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

    REQUIRED_KEYS = %w[identifier name licence version calendar].freeze

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
      version.save!
      version
    end

    def calendar = data["calendar"]

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
    end
  end
end
