# frozen_string_literal: true

module Cases
  # The one path that reads authored Case data into the engine. It is a thin
  # seam rather than an authoring pipeline: ADR 0001 keeps the Case format
  # behind a single loader precisely so it can later be a fetch.
  #
  # A published Version never changes again, so re-importing one is refused. A
  # draft is the professor's working copy, so re-importing one replaces its
  # calendar.
  class Import
    InvalidCase = Class.new(StandardError)
    PublishedVersionExists = Class.new(StandardError)

    REQUIRED_KEYS =
      %w[identifier name licence version calendar budget actions clients terms documents].freeze
    REQUIRED_BUDGET_KEYS =
      %w[per_day exchange_pool exhibit_price closing_knee closing_preparation
        closing_exchange].freeze
    REQUIRED_ACTION_KEYS = %w[cost lead_time_days half].freeze
    REQUIRED_DOCUMENT_KEYS = %w[title body].freeze
    # Provenance's authored three. A document names the Action it waits behind
    # or the hand it sits in at the open, and never both — that xor is what
    # makes *doors visible, contents hidden* checkable.
    HANDS = (CaseDocument::PROVENANCES - [CaseDocument::DISCOVERABLE]).freeze
    REQUIRED_EXHIBIT_KEYS = %w[target shift bears_on].freeze
    # A band with one line repeats itself verbatim on a professor's second
    # Consult, which is the failure the several-variants rule exists to prevent.
    MINIMUM_VARIANTS = 2
    # Every fold has to land in a band, so the lowest one begins where the
    # Client does.
    THE_UNMOVED_CLIENT = 0
    # A Client's bound is authored in whole money, because that is how an author
    # thinks about how far a party can be moved. It is held in cents, because
    # that is how money is held.
    CENTS_PER_UNIT = 100
    # The Budget's whole numbers. `closing_knee` is the one fraction and is
    # checked on its own.
    BUDGET_COUNTS =
      %w[per_day exchange_pool exhibit_price closing_preparation closing_exchange].freeze

    # The floor belongs to the half itself, so it is the model's to state.
    PLAYABLE_EXCHANGE_HALF = DayBudget::PLAYABLE_EXCHANGE_HALF
    # What an Offer costs to commit. It is engine rather than authored, and the
    # Exhibit's price is checked against what is left of the pool over it.
    OFFER_COST = CommittedOffer::EXCHANGE_COST

    def self.call(path) = new(path).call

    def initialize(path)
      @path = Pathname(path)
      @data = YAML.safe_load_file(@path, permitted_classes: [Date])
    rescue Psych::Exception, SystemCallError => e
      raise InvalidCase, "#{path} is not readable as a Case: #{e.message}"
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        version = case_version_for(authored_case)
        version.calendar_days.destroy_all
        calendar.each_with_index do |date, index|
          version.calendar_days.create!(ordinal: index + 1, in_fiction_date: date)
        end
        # Documents wait behind Actions and bear on Terms, and a Client's
        # aspirations name Terms too, so both go first on the way out and the
        # vocabulary they point at goes last on the way back in.
        version.documents.destroy_all
        version.clients.destroy_all
        version.actions.destroy_all
        version.terms.destroy_all

        actions.each do |kind, authored_action|
          version.actions.create!(
            kind: kind,
            cost: authored_action["cost"],
            lead_time_days: authored_action["lead_time_days"],
            half: authored_action["half"]
          )
        end
        terms.each { |key| version.terms.create!(key: key) }
        clients.each do |role, authored_client|
          client = version.clients.create!(
            role: role,
            bound_cents: authored_client["bound"] * CENTS_PER_UNIT,
            opening_statement: authored_client["opening_statement"],
            portrait_seed: authored_client["portrait_seed"],
            **settlement_lines_for(authored_client)
          )
          import_aspirations(client, authored_client["aspirations"])
          import_bands(client, authored_client["bands"])
        end
        import_documents(version)
        version.reload
      end
    end

    private

    attr_reader :path, :data

    def authored_case
      ::Case.find_or_initialize_by(identifier: data["identifier"]).tap do |authored|
        authored.update!(name: data["name"], licence: data["licence"])
      end
    end

    def case_version_for(authored)
      version = authored.versions.find_or_initialize_by(version: data["version"])
      if version.persisted? && version.published?
        raise PublishedVersionExists,
          "#{data["identifier"]} #{data["version"]} is published and never changes again"
      end

      version.published_at = data["published"] ? Time.current : nil
      version.budget_per_day = budget["per_day"]
      version.exchange_pool = budget["exchange_pool"]
      version.exhibit_price = budget["exhibit_price"]
      version.closing_knee = budget["closing_knee"]
      version.closing_preparation = budget["closing_preparation"]
      version.closing_exchange = budget["closing_exchange"]
      version.save!
      version
    end

    # What a Client says out loud about the Terms, and the Terms Board's third
    # track. The set is sparse by design: a Term absent here is one this Client
    # is indifferent about, and its track carries the two live positions and no
    # marker — so nothing demands a row per Client per Term.
    #
    # An amount is authored in whole money like the bound, and is absent on a
    # Term that carries no figure: a Client wanting an apology wants an apology.
    def import_aspirations(client, authored_aspirations)
      vocabulary = client.case_version.terms.index_by(&:key)

      (authored_aspirations || {}).each do |key, amount|
        client.aspirations.create!(
          case_term: vocabulary.fetch(key),
          amount_cents: amount && amount * CENTS_PER_UNIT
        )
      end
    end

    # What the Client says about where they stand, and the edge each band
    # begins at. Written in the engine's own band order rather than the order
    # the file happens to list them in, so the thresholds go in ascending
    # whatever the author wrote — and the variants keep the authored order,
    # because that is the order they are spoken in.
    def import_bands(client, authored_bands)
      CaseClientBand::BANDS.each do |key|
        authored = authored_bands.fetch(key)
        band = client.bands.create!(key: key, threshold: authored["at"])
        authored["lines"].each { |body| band.lines.create!(body: body) }
      end
    end

    # The two settlement lines, as the columns that hold them. Read through
    # `CaseClient::SETTLEMENT_LINES` rather than named twice here, so the
    # authored key and the column it lands in stay one decision.
    def settlement_lines_for(authored_client)
      settlement = authored_client["settlement"]
      CaseClient::SETTLEMENT_LINES.to_h do |acceptance_role, column|
        [column, settlement[acceptance_role]]
      end
    end

    # An Exhibit is a property some documents carry and most do not, so it is
    # written with the document rather than beside it.
    def import_documents(version)
      menu = version.actions.index_by(&:kind)
      vocabulary = version.terms.index_by(&:key)

      documents.each do |identifier, authored_document|
        exhibit = authored_document["exhibit"]
        # `.presence`, because the xor below was checked with `present?` and a
        # blank string is truthy: without it `hand: ""` passes validation and
        # then dies as a model error naming no file and no document.
        hand = authored_document["hand"].presence
        document = version.documents.create!(
          # A door or a hand, never both. The Provenance is written into the
          # column rather than left to be inferred from which key was authored,
          # so what a read gets back is what the Case said.
          case_action: (menu.fetch(authored_document["action"]) unless hand),
          provenance: hand || CaseDocument::DISCOVERABLE,
          identifier: identifier,
          title: authored_document["title"],
          body: authored_document["body"],
          exhibit_target_role: exhibit&.fetch("target"),
          exhibit_shift_fraction: exhibit&.fetch("shift")
        )
        exhibit&.fetch("bears_on")&.each do |key|
          document.document_terms.create!(case_term: vocabulary.fetch(key))
        end
      end
    end

    def calendar = data["calendar"]

    def actions = data["actions"]

    def budget = data["budget"]

    def clients = data["clients"]

    def terms = data["terms"]

    def documents = data["documents"]

    def validate!
      raise InvalidCase, "#{path} does not hold a Case" unless data.is_a?(Hash)

      missing = REQUIRED_KEYS.reject { |key| data[key].present? }
      raise InvalidCase, "#{path} is missing #{missing.join(", ")}" if missing.any?

      raise InvalidCase, "#{path} authors no calendar" unless calendar.is_a?(Array) && calendar.any?

      unless calendar.all?(Date)
        raise InvalidCase, "#{path} authors a calendar entry that is not a date"
      end

      unless calendar.each_cons(2).all? { |earlier, later| earlier < later }
        raise InvalidCase, "#{path} authors a calendar that is not in order"
      end

      validate_budget!
      validate_actions!
      validate_clients!
      validate_terms!
      validate_documents!
    end

    # An Exhibit targets a Client, so a Case authors one for each Side.
    def validate_clients!
      raise InvalidCase, "#{path} authors no clients" unless clients.is_a?(Hash)

      unless clients.keys.sort == Side::ROLES.sort
        raise InvalidCase,
          "#{path} authors clients for #{clients.keys.sort.join(", ")} rather than " \
          "one for each of #{Side::ROLES.sort.join(", ")}"
      end

      clients.each do |role, authored_client|
        authored = authored_client.is_a?(Hash) ? authored_client : {}
        bound = authored["bound"]
        unless bound.is_a?(Integer) && bound.positive?
          raise InvalidCase,
            "#{path} authors the #{role} Client with a bound of #{bound.inspect}, " \
            "which is not a whole amount of money it can be moved by"
        end

        # What the Client says they want, on the Day the Team first sits down.
        # It is one of the Morning Briefing's what-you-start-with sections, so a
        # Case without it imports into a briefing with a hole in it.
        unless authored["opening_statement"].is_a?(String) && authored["opening_statement"].present?
          raise InvalidCase,
            "#{path} authors no opening statement for the #{role} Client, " \
            "which is what their Team reads on Day 1"
        end

        validate_portrait_seed!(role, authored["portrait_seed"])
        validate_settlement!(role, authored["settlement"])
        validate_bands!(role, authored["bands"])
        validate_aspirations!(role, authored["aspirations"])
      end

      validate_distinct_faces!
    end

    # The whole of what a Case says about a Client's face. A Case that authors
    # none does not import, as loudly as one missing an opening statement: the
    # portrait is the Client's beat on both its occasions, and there is no
    # fallback face to draw under the words.
    def validate_portrait_seed!(role, seed)
      return if seed.is_a?(String) && seed.present?

      raise InvalidCase,
        "#{path} authors no portrait seed for the #{role} Client, " \
        "which is the whole of what a Case says about their face"
    end

    # The two Clients of one Case are the only pair anybody can ever see
    # together: Teams in different Simulations never meet, and a Team sees only
    # its own Client. So this is the one collision that matters, and it is
    # checked here rather than carried by the seed — two seeds collide when they
    # *compose* to the same person, which is a property of the part set and not
    # of the string.
    #
    # It follows that a Case can import today and stop importing after a reskin,
    # and that is correct: a set with a shallower hair group is a set in which
    # two faces the author had told apart are one face.
    def validate_distinct_faces!
      drawn = clients.transform_values { |authored| Portraits::Identity.for(authored["portrait_seed"]) }
      return if drawn.values.uniq.size == drawn.size

      raise InvalidCase,
        "#{path} seeds its #{drawn.keys.sort.join(" and ")} Clients to the same face " \
        "(#{drawn.values.first}); they are the one pair a Team ever sees together, " \
        "so reroll one of them"
    end

    # The settlement beat, keyed on which Side accepted. A Case that does not
    # supply both lines for both Clients does not import, as loudly as one
    # missing an opening statement: an executed instrument is the last thing a
    # Team reads and there is no fallback line to render under it.
    #
    # There are no variants. A settlement node is spoken exactly once, so a
    # speak-count never advances and a variant would always resolve to the
    # first — see ADR 0007.
    def validate_settlement!(role, authored_settlement)
      settlement = authored_settlement.is_a?(Hash) ? authored_settlement : {}
      missing = CaseClient::ACCEPTANCE_ROLES.reject do |acceptance_role|
        settlement[acceptance_role].is_a?(String) && settlement[acceptance_role].present?
      end
      return if missing.empty?

      raise InvalidCase,
        "#{path} authors no settlement line for the #{role} Client where they " \
        "#{missing.map { |acceptance_role| acceptance_role.tr("_", " ") }.join(" or ")}, " \
        "which is what they say over the executed instrument"
    end

    # The Reaction Band: what this Client says about where they stand, and the
    # only read a Team ever gets on how far their Client has moved. A Case that
    # authors none does not import, as loudly as one missing an opening
    # statement — a Consult would otherwise buy a Client with nothing to say.
    #
    # Two bands is engine and the edges are the Case's, so the keys are checked
    # against the engine's pair and the thresholds only for shape and order.
    def validate_bands!(role, authored_bands)
      bands = authored_bands.is_a?(Hash) ? authored_bands : {}
      if bands.empty?
        raise InvalidCase,
          "#{path} authors no bands for the #{role} Client, which is the whole of " \
          "what they can say when their Team consults them"
      end

      unless bands.keys.sort == CaseClientBand::BANDS.sort
        raise InvalidCase,
          "#{path} authors #{bands.keys.sort.join(", ")} for the #{role} Client rather than " \
          "one band for each of #{CaseClientBand::BANDS.join(", ")}"
      end

      CaseClientBand::BANDS.each { |key| validate_band!(role, key, bands.fetch(key)) }
      validate_band_edges!(role, bands)
    end

    def validate_band!(role, key, authored_band)
      band = authored_band.is_a?(Hash) ? authored_band : {}
      edge = band["at"]
      unless edge.is_a?(Numeric) && edge >= THE_UNMOVED_CLIENT && edge <= ClientShift::WHOLE_BOUND
        raise InvalidCase,
          "#{path} authors the #{role} Client's #{key} band at #{edge.inspect}, which is not " \
          "a fraction of the bound they cross into it at"
      end

      lines = band["lines"]
      unless lines.is_a?(Array) && lines.all? { |body| body.is_a?(String) && body.present? }
        raise InvalidCase,
          "#{path} authors the #{role} Client's #{key} band saying #{lines.inspect}, " \
          "which is not a set of lines they could say"
      end

      return if lines.size >= MINIMUM_VARIANTS

      # A node the engine can only ever speak one way. The Consult is priced to
      # be bought more than once, so the second one would come back word for
      # word — which is the tell the variants exist to prevent.
      raise InvalidCase,
        "#{path} gives the #{role} Client #{lines.size} line for their #{key} band; " \
        "a Consult can be bought twice, so a node carries at least #{MINIMUM_VARIANTS} variants"
    end

    # The bands are a partition of the bound, so the lowest begins where the
    # Client does and each one after it begins above the one before. A set that
    # starts above zero leaves an unmoved Client in no band at all, and the fold
    # would have nothing to answer with.
    def validate_band_edges!(role, bands)
      edges = CaseClientBand::BANDS.map { |key| bands.fetch(key)["at"] }

      unless edges.first == THE_UNMOVED_CLIENT
        raise InvalidCase,
          "#{path} starts the #{role} Client's #{CaseClientBand::BANDS.first} band at " \
          "#{edges.first}, leaving a Client who has not moved yet in no band at all"
      end

      return if edges.each_cons(2).all? { |lower, higher| lower < higher }

      raise InvalidCase,
        "#{path} authors the #{role} Client's bands at #{edges.join(", ")}, which do not climb " \
        "through the bound in the order #{CaseClientBand::BANDS.join(", ")}"
    end

    # What a Client says out loud about the Terms. Sparse on purpose — a Term
    # absent here is one this Client is indifferent about — so an empty set is
    # authored rather than missing, and nothing checks for completeness.
    def validate_aspirations!(role, authored_aspirations)
      return if authored_aspirations.nil?

      unless authored_aspirations.is_a?(Hash)
        raise InvalidCase,
          "#{path} authors the #{role} Client's aspirations as " \
          "#{authored_aspirations.inspect}, which is not a set of Terms they want"
      end

      unknown = authored_aspirations.keys - terms
      if unknown.any?
        raise InvalidCase,
          "#{path} has the #{role} Client wanting #{unknown.join(", ")}, " \
          "which this Case authors no Term for"
      end

      authored_aspirations.each do |key, amount|
        # Absent on a Term that carries no figure, which is most of them. A
        # Client wanting an apology wants an apology.
        if amount && !(amount.is_a?(Integer) && amount.positive?)
          raise InvalidCase,
            "#{path} has the #{role} Client wanting #{amount.inspect} of #{key}, which is " \
            "neither a whole amount of money nor the Term wanted without a figure"
        end

        # Money is the one Term that carries a figure, which is the rule an
        # Offer's Terms are already held to. A Client aspiring to 5,000 of
        # apology would put a money figure on a Terms Board track whose other
        # two slots cannot hold one.
        next if (key == CaseTerm::MONEY) == !amount.nil?

        raise InvalidCase,
          "#{path} has the #{role} Client wanting #{key} " \
          "#{amount.nil? ? "without an amount" : "for #{amount}"}; " \
          "#{CaseTerm::MONEY} is the one Term an amount belongs to"
      end
    end

    # The vocabulary an Offer is built from and an Exhibit bears on.
    def validate_terms!
      unless terms.is_a?(Array) && terms.any? && terms.all?(String)
        raise InvalidCase, "#{path} authors no terms for an Offer to be built from"
      end

      duplicated = terms.tally.select { |_key, count| count > 1 }.keys
      return if duplicated.empty?

      raise InvalidCase, "#{path} authors #{duplicated.join(", ")} twice; Terms are atomic"
    end

    def validate_documents!
      raise InvalidCase, "#{path} authors no documents" unless documents.is_a?(Hash) && documents.any?

      documents.each { |identifier, authored| validate_document!(identifier, authored) }
    end

    def validate_document!(identifier, authored_document)
      authored = authored_document.is_a?(Hash) ? authored_document : {}
      if REQUIRED_DOCUMENT_KEYS.any? { |key| authored[key].blank? }
        raise InvalidCase,
          "#{path} authors #{identifier} without #{REQUIRED_DOCUMENT_KEYS.join(", ")}"
      end

      validate_provenance!(identifier, authored)
      validate_exhibit!(identifier, authored["exhibit"])
      validate_open_hand_exhibit!(identifier, authored)
    end

    # The xor. Every discoverable document sits behind some Action, and nothing
    # a Team starts with can also be something it finds — which is the whole of
    # what makes *doors visible, contents hidden* a thing a spec can check.
    def validate_provenance!(identifier, authored)
      door = authored["action"]
      hand = authored["hand"]

      if door.present? == hand.present?
        raise InvalidCase,
          "#{path} authors #{identifier} with #{door.present? ? "both an action and a hand" :
            "neither an action nor a hand"}; a document waits behind one or sits in the other"
      end

      if hand.present? && !HANDS.include?(hand)
        raise InvalidCase,
          "#{path} puts #{identifier} in #{hand}, which is not a hand at the open"
      end

      return if hand.present?

      unless actions.key?(door)
        raise InvalidCase,
          "#{path} hides #{identifier} behind #{door}, which is not on this Case's Action menu"
      end

      return unless door == CaseAction::CONSULT_CLIENT

      # A Consult is answered by the Client rather than by paper, and until now
      # that was a comment on `CaseAction` rather than a rule — this importer
      # maps documents onto the menu by key and would have taken one.
      #
      # It is a rule because a historical read rests on it. `Days::Command`
      # writes the Docket row and lands a lead-zero spend's documents inside one
      # transaction, and a Consult is lead-zero: a shift landing there would
      # share the spend's timestamp, and the band folded as of that instant
      # would be order-ambiguous. Refusing the Case removes the tiebreak rather
      # than stating one — see ADR 0006.
      raise InvalidCase,
        "#{path} hides #{identifier} behind #{CaseAction::CONSULT_CLIENT}, which is answered " \
        "by the Client rather than by paper; a Consult yields no documents"
    end

    # Ammunition a Team walks in with is a position the Case authored and Par is
    # authored against it. An unfavorable Exhibit at the open is refused: its
    # shift would land before the first Day is played, spending the Client's
    # bound with no Docket line behind it and no beat to read it in.
    #
    # A document in both hands is in the hand of whichever Client it would
    # target, so it may carry no Exhibit at all.
    def validate_open_hand_exhibit!(identifier, authored)
      hand = authored["hand"]
      target = authored.dig("exhibit", "target")
      return if hand.blank? || target.nil?
      return if hand != CaseDocument::BOTH_SIDES && target != hand

      raise InvalidCase,
        "#{path} puts #{identifier} in #{hand}'s hand at the open carrying an Exhibit " \
        "against the #{target} Client, which would move them before the first Day is played"
    end

    # A document may carry an Exhibit and most do not. One that does carries a
    # target, a shift as a fraction of that target's bound, and the Terms it
    # bears on — all three or none of them.
    def validate_exhibit!(identifier, exhibit)
      return if exhibit.nil?

      unless exhibit.is_a?(Hash) && REQUIRED_EXHIBIT_KEYS.none? { |key| exhibit[key].blank? }
        raise InvalidCase,
          "#{path} gives #{identifier} an Exhibit without #{REQUIRED_EXHIBIT_KEYS.join(", ")}"
      end

      unless Side::ROLES.include?(exhibit["target"])
        raise InvalidCase,
          "#{path} points #{identifier}'s Exhibit at #{exhibit["target"]}, which is not a Client"
      end

      shift = exhibit["shift"]
      unless shift.is_a?(Numeric) && shift.positive? && shift <= 1
        raise InvalidCase,
          "#{path} gives #{identifier}'s Exhibit a shift of #{shift.inspect}, which is not a " \
          "fraction of the target Client's bound moving them toward settleability"
      end

      # Checked as authored rather than coerced: a lone Term written without a
      # list passes every check above, and would reach `import_documents` to be
      # iterated as a String rather than come back as this importer's refusal.
      bears_on = exhibit["bears_on"]
      unless bears_on.is_a?(Array) && bears_on.all? { |key| key.is_a?(String) && key.present? }
        raise InvalidCase,
          "#{path} has #{identifier}'s Exhibit bearing on #{bears_on.inspect}, " \
          "which is not a list of the Terms it bears on"
      end

      unknown = bears_on - terms
      return if unknown.empty?

      raise InvalidCase,
        "#{path} has #{identifier}'s Exhibit bearing on #{unknown.join(", ")}, " \
        "which this Case authors no Term for"
    end

    def validate_budget!
      raise InvalidCase, "#{path} authors no budget" unless budget.is_a?(Hash)

      missing = REQUIRED_BUDGET_KEYS.reject { |key| budget[key].present? }
      raise InvalidCase, "#{path} authors a budget missing #{missing.join(", ")}" if missing.any?

      validate_budget_shape!

      [["exchange_pool", "exchange half"], ["closing_exchange", "closing exchange half"]]
        .each do |key, name|
          next if budget[key] >= PLAYABLE_EXCHANGE_HALF

          raise InvalidCase,
            "#{path} authors a #{name} of #{budget[key]}, under the #{PLAYABLE_EXCHANGE_HALF} " \
            "points an Offer with one Exhibit behind it costs"
        end

      validate_exhibit_price!
    end

    # The Exhibit's price and the exchange pool are one decision rather than
    # two. An Exhibit rides a committed Offer, so a price that puts the pair past
    # the pool prices out every Exhibit in the Case — at a pool of two an Exhibit
    # costing two means nothing can ever be played, and separation across the
    # joint grid falls from 84 to 10. The narrower of the two halves is the one
    # to check: the closing half only ever widens.
    def validate_exhibit_price!
      price = budget["exhibit_price"]
      unless price >= 1
        raise InvalidCase, "#{path} authors an Exhibit costing #{price}, which is not a spend"
      end

      return if OFFER_COST + price <= budget["exchange_pool"]

      raise InvalidCase,
        "#{path} prices an Exhibit at #{price} against an exchange half of " \
        "#{budget["exchange_pool"]}, which leaves no Offer for it to ride"
    end

    # Types and ranges before any comparison, because a value of the wrong shape
    # otherwise passes import and fails much later and much further away — a
    # string blows up the comparison below, and a negative allowance reaches the
    # Day it opens and trips a `day_budgets` CHECK mid-Simulation.
    def validate_budget_shape!
      BUDGET_COUNTS.each do |key|
        next if budget[key].is_a?(Integer)

        raise InvalidCase,
          "#{path} authors a budget #{key.tr("_", " ")} of #{budget[key].inspect}, " \
          "which is not a whole number of points"
      end

      knee = budget["closing_knee"]
      unless knee.is_a?(Numeric) && knee.positive? && knee <= 1
        raise InvalidCase,
          "#{path} authors a closing knee of #{knee.inspect}, which is not a " \
          "fraction of the Simulation"
      end

      if budget["closing_preparation"].negative?
        raise InvalidCase,
          "#{path} authors a closing preparation half of " \
          "#{budget["closing_preparation"]}, which is less than nothing"
      end

      # The taper takes a Section's Budget cut out of the preparation half and
      # never out of the brake, so a Budget authored under its own exchange pool
      # writes a negative preparation half on the first Day that opens.
      return if budget["per_day"] >= budget["exchange_pool"]

      raise InvalidCase,
        "#{path} authors #{budget["per_day"]} points a Day against an exchange " \
        "half of #{budget["exchange_pool"]}, leaving nothing to prepare with"
    end

    # An Action kind is engine, so a Case may price the kinds it offers and may
    # not invent one. Everything else about an Action — the cost, the lead time
    # and the half it draws on — is the Case's.
    def validate_actions!
      raise InvalidCase, "#{path} authors no actions" unless actions.is_a?(Hash) && actions.any?

      actions.each do |kind, authored_action|
        unless CaseAction::KINDS.include?(kind)
          raise InvalidCase, "#{path} authors #{kind}, which is not an Action the engine knows"
        end

        validate_action!(kind, authored_action)
      end
    end

    def validate_action!(kind, authored_action)
      # A lead time of zero is a legal Action, so an authored value is missing
      # only when it is nil, never when it is falsy.
      authored = authored_action.is_a?(Hash) ? authored_action : {}
      if REQUIRED_ACTION_KEYS.any? { |key| authored[key].nil? }
        raise InvalidCase, "#{path} authors #{kind} without #{REQUIRED_ACTION_KEYS.join(", ")}"
      end

      # Points and Days are whole. A fractional one would otherwise reach the
      # model and come back as a validation failure rather than as this
      # importer's own refusal.
      %w[cost lead_time_days].each do |key|
        next if authored[key].is_a?(Integer)

        raise InvalidCase,
          "#{path} authors #{kind} with a #{key.tr("_", " ")} of " \
          "#{authored[key].inspect}, which is not a whole number"
      end

      raise InvalidCase, "#{path} authors #{kind} costing nothing" unless authored["cost"] >= 1

      if authored["lead_time_days"].negative?
        raise InvalidCase, "#{path} authors #{kind} with a lead time reaching backwards"
      end

      return if DayBudget::HALVES.include?(authored["half"])

      raise InvalidCase,
        "#{path} authors #{kind} drawing on #{authored["half"]}, " \
        "which is not a half of the Action Budget"
    end
  end
end
