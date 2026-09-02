# frozen_string_literal: true

module Simulations
  # Creating a Simulation lays out its whole run at once: two Sides, and every
  # Day of the pinned Case Version's calendar, in one transaction.
  #
  # The Days exist before the first is played because an Action taken today has
  # to be able to name the Day its result lands on, and because an Instructor
  # previews the schedule before Day 1.
  class Create
    def self.call(...) = new(...).call

    def initialize(section:, case_version:)
      @section = section
      @case_version = case_version
    end

    def call
      ActiveRecord::Base.transaction do
        simulation = Simulation.create!(section: section, case_version: case_version)
        Side::ROLES.each { |role| simulation.sides.create!(role: role) }
        case_version.calendar_days.each do |authored_day|
          simulation.days.create!(
            ordinal: authored_day.ordinal,
            in_fiction_date: authored_day.in_fiction_date
          )
        end
        simulation
      end
    end

    private

    attr_reader :section, :case_version
  end
end
