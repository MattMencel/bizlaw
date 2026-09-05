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
    REQUIRED_DOCUMENT_KEYS = %w[action title body].freeze
    REQUIRED_EXHIBIT_KEYS = %w[target shift bears_on].freeze
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
        # Documents wait behind Actions and bear on Terms, so they go first on
        # the way out and last on the way back in.
        version.documents.destroy_all
        version.actions.destroy_all
        actions.each do |kind, authored_action|
          version.actions.create!(
            kind: kind,
            cost: authored_action["cost"],
            lead_time_days: authored_action["lead_time_days"],
            half: authored_action["half"]
          )
        end
        version.clients.destroy_all
        clients.each do |role, authored_client|
          version.clients.create!(role: role, bound_cents: authored_client["bound"] * CENTS_PER_UNIT)
        end
        version.terms.destroy_all
        terms.each { |key| version.terms.create!(key: key) }
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

    # An Exhibit is a property some documents carry and most do not, so it is
    # written with the document rather than beside it.
    def import_documents(version)
      menu = version.actions.index_by(&:kind)
      vocabulary = version.terms.index_by(&:key)

      documents.each do |identifier, authored_document|
        exhibit = authored_document["exhibit"]
        document = version.documents.create!(
          case_action: menu.fetch(authored_document["action"]),
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
        bound = authored_client.is_a?(Hash) ? authored_client["bound"] : nil
        next if bound.is_a?(Integer) && bound.positive?

        raise InvalidCase,
          "#{path} authors the #{role} Client with a bound of #{bound.inspect}, " \
          "which is not a whole amount of money it can be moved by"
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

      # Provenance: every discoverable document sits behind some Action.
      unless actions.key?(authored["action"])
        raise InvalidCase,
          "#{path} hides #{identifier} behind #{authored["action"]}, " \
          "which is not on this Case's Action menu"
      end

      validate_exhibit!(identifier, authored["exhibit"])
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
