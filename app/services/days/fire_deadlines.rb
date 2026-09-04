# frozen_string_literal: true

module Days
  # The Instructor's deadline firing, which closes a Day exactly as a second
  # commit would.
  #
  # It resolves *which* Days are due and hands each to the one close path; it
  # closes nothing itself. A plain service rather than a job because nothing
  # schedules jobs yet — solid_queue is in the Gemfile with no queue schema and
  # no recurring config behind it, and a job nothing runs is a job in name only.
  # Whatever eventually calls this on a timer calls this.
  class FireDeadlines
    def self.call(...) = new(...).call

    def initialize(scope: Day.all, at: Time.current)
      @scope = scope
      @at = at
    end

    # The Days this call closed. A Day another caller closed first is not in it,
    # because the compare-and-set told this one it lost.
    def call
      due.select { |day| Close.call(day, at: at) }
    end

    private

    attr_reader :scope, :at

    def due = scope.open.where(deadline_at: ..at).order(:id)
  end
end
