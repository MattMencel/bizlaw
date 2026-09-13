# frozen_string_literal: true

module Cases
  # The one path that reads authored Case data into the engine. It is a thin
  # seam rather than an authoring pipeline: ADR 0001 keeps the Case format
  # behind a single loader precisely so it can later be a fetch.
  #
  # A published Version never changes again, so re-importing one is refused. A
  # draft is the professor's working copy, so re-importing one replaces its
  # calendar.
  #
  # What each authored object refuses on lives in its own `Gate` under this
  # class — the file grows by one gate when a Case learns to author one more
  # thing, rather than by thirty lines here. The gates are not a second seam:
  # they read the parsed Hash, touch no table, and are reached only from
  # `validate!`.
  class Import
    InvalidCase = Class.new(StandardError)
    PublishedVersionExists = Class.new(StandardError)

    REQUIRED_KEYS =
      %w[identifier name licence version calendar budget actions clients terms documents].freeze

    # A Client's bound is authored in whole money, because that is how an author
    # thinks about how far a party can be moved. It is held in cents, because
    # that is how money is held.
    CENTS_PER_UNIT = 100

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

    # The Case's own shape, then each authored object's gate. Nothing below the
    # top level is refused here: a gate owns every sentence a professor reads
    # about the object it is named for.
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

      # In the order a Case is refused in, which is the order the refusals
      # already depended on: a Client with no bound is refused for the bound and
      # never for the bands.
      [BudgetGate, ActionsGate, ClientsGate, TermsGate, DocumentsGate]
        .each { |gate| gate.check!(path, data) }
    end

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
  end
end
