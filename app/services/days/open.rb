# frozen_string_literal: true

module Days
  # Opening a Day hands each Side its Action Budget for that Day, in two halves.
  #
  # The Budget is not the same size every Day. Past a knee at three fifths of the
  # Simulation the preparation allowance collapses to roughly the price of a
  # Consult and the exchange half widens by one point, because discovery bought
  # after the lead times can no longer land and a flat Budget would hand a Team
  # three or four Days on which the ungated half buys nothing at all.
  #
  # The quota is written once. A Day that already carries its rows is left
  # alone, so a re-open cannot rewrite a Day already played — which is what
  # makes a double Day-open harmless rather than merely improbable.
  class Open
    def self.call(...) = new(...).call

    def initialize(day)
      @day = day
    end

    def call
      quota = quota_for

      simulation.sides.map do |side|
        # The unique index is what refuses the second write, so the Day that has
        # already opened keeps the quota it was written with.
        DayBudget.create_or_find_by!(side: side, day: day) do |budget|
          budget.preparation_budget = quota.fetch(:preparation)
          budget.exchange_budget = quota.fetch(:exchange)
        end
      end
    end

    private

    attr_reader :day

    def simulation = day.simulation

    def case_version = simulation.case_version

    # The taper is engine arithmetic over authored numbers. The exchange half is
    # a count of points rather than a share of the Budget, so a Section that
    # shrinks the Budget takes it out of the preparation half and never out of
    # the brake.
    def quota_for
      if closing?
        {preparation: case_version.closing_preparation, exchange: case_version.closing_exchange}
      else
        pool = case_version.exchange_pool
        {preparation: budget_per_day - pool, exchange: [pool, budget_per_day].min}
      end
    end

    def closing? = day.ordinal > case_version.closing_knee * simulation.day_count

    # The Case's reference value unless the Section turned the knob.
    def budget_per_day = simulation.section.budget_per_day || case_version.budget_per_day
  end
end
