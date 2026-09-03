# frozen_string_literal: true

module Days
  # The single command seam every act in the Day enters through. Nothing else
  # writes to the Day's ledgers, so there is one place a rule is enforced and
  # one place a test binds.
  #
  # Every act has two verbs. `quote` returns the cost, the half it draws on,
  # what the Side will have left today if it goes through, and the Day the
  # result lands on — and writes nothing. `apply` performs it.
  #
  # The confirmation dialog every spend shows is rendered from `quote`, so the
  # number a student confirms is computed by the same code path that charges
  # them. A spend is irreversible and, unlike an Offer, ungated by a Second, so
  # every spend confirms — uniformly, never only a first one.
  #
  # `quote` on an act the Side cannot afford returns the refusal rather than
  # raising, so an Action Board can disable a control without a failed write.
  # `apply` on the same act raises, because a command that cannot be performed
  # is not a question.
  class Command
    ACTS = %i[spend].freeze

    # What a student is shown before they confirm, and what `apply` then
    # charges. A refused quote carries no remaining-after and no landing Day:
    # there is no negative Budget and no Day past the last one to render.
    Quote = Data.define(:cost, :half, :remaining_after, :landing_day, :refusal) do
      def refused? = !refusal.nil?

      def affordable? = !refused?
    end

    # Raised by `apply` on an act `quote` refuses. It carries the quote, so a
    # caller can say which rule turned it down.
    class Refused < StandardError
      attr_reader :quote

      def initialize(quote)
        @quote = quote
        super(quote.refusal.to_s)
      end
    end

    def self.quote(...) = new(...).quote

    def self.apply(...) = new(...).apply

    def initialize(act:, side:, day:, by:, **details)
      raise ArgumentError, "unknown act #{act.inspect}" unless ACTS.include?(act)

      @act = act
      @side = side
      @day = day
      @by = by
      @details = details
    end

    def quote
      return @quote if defined?(@quote)

      @quote = build_quote
    end

    def apply
      raise Refused, quote if quote.refused?

      # One row, and the trigger on it re-folds the half's spent counter. The
      # Budget's CHECK is underneath both, so a half pushed past its ceiling by
      # any insert path takes the insert down rather than going negative.
      side.docket_entries.create!(
        day: day,
        lands_on_day: quote.landing_day,
        spent_by: by,
        case_action: action,
        cost: quote.cost,
        half: quote.half
      )
    end

    private

    attr_reader :act, :side, :day, :by, :details

    # The authored Action this act spends on. A kind the Case does not author is
    # a caller with a menu the engine never offered, not a refusal a student
    # should see.
    def action
      @action ||= side.case_version.actions.find_by(kind: details.fetch(:kind)) ||
        raise(ArgumentError, "#{details.fetch(:kind)} is not on this Case's Action menu")
    end

    def build_quote
      landing_day = landing_day_for
      return refusal(:the_result_would_land_past_the_last_day) if landing_day.nil?

      budget = side.budget_on(day)
      return refusal(:the_day_has_not_opened, landing_day: landing_day) if budget.nil?

      remaining_after = budget.remaining_in(action.half) - action.cost
      return refusal(:the_budget_cannot_cover_it, landing_day: landing_day) if remaining_after.negative?

      Quote.new(
        cost: action.cost,
        half: action.half,
        remaining_after: remaining_after,
        landing_day: landing_day,
        refusal: nil
      )
    end

    def refusal(reason, landing_day: nil)
      Quote.new(
        cost: action.cost,
        half: action.half,
        remaining_after: nil,
        landing_day: landing_day,
        refusal: reason
      )
    end

    # A lead time of zero lands the result on the Day it was bought. Past the
    # last Day there is no Day to land on, and burning points on discovery that
    # can never arrive is what the refusal exists to prevent.
    def landing_day_for
      day.simulation.days.find_by(ordinal: day.ordinal + action.lead_time_days)
    end
  end
end
