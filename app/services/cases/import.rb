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

    REQUIRED_KEYS = %w[identifier name licence version calendar budget actions].freeze
    REQUIRED_BUDGET_KEYS =
      %w[per_day exchange_pool closing_knee closing_preparation closing_exchange].freeze
    REQUIRED_ACTION_KEYS = %w[cost lead_time_days half].freeze
    # The Budget's whole numbers. `closing_knee` is the one fraction and is
    # checked on its own.
    BUDGET_COUNTS =
      %w[per_day exchange_pool closing_preparation closing_exchange].freeze

    # The floor belongs to the half itself, so it is the model's to state.
    PLAYABLE_EXCHANGE_HALF = DayBudget::PLAYABLE_EXCHANGE_HALF

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
        version.actions.destroy_all
        actions.each do |kind, authored_action|
          version.actions.create!(
            kind: kind,
            cost: authored_action["cost"],
            lead_time_days: authored_action["lead_time_days"],
            half: authored_action["half"]
          )
        end
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
      version.closing_knee = budget["closing_knee"]
      version.closing_preparation = budget["closing_preparation"]
      version.closing_exchange = budget["closing_exchange"]
      version.save!
      version
    end

    def calendar = data["calendar"]

    def actions = data["actions"]

    def budget = data["budget"]

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
