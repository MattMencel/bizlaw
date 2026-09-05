# frozen_string_literal: true

module Days
  # The single command seam every act in the Day enters through. Nothing else
  # writes to the Day's ledgers, so there is one place a rule is enforced and
  # one place a test binds.
  #
  # Every act has two verbs. `quote` returns the cost, the half it draws on,
  # what the Side will have left today if it goes through, and the Day the
  # result lands on — and writes nothing. `apply` performs it and returns what
  # the act produced: the Docket row for a spend, the committed Offer for a
  # commit.
  #
  # There are two acts. `:spend` buys an Action off the Case's menu, out of the
  # half that Action draws on. `:commit_offer` puts the Team's staged Offer on
  # the table for one point of the exchange half — a Boardroom act rather than a
  # menu entry, which is why it names no authored Action, and the only act here
  # that is gated by a Second.
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
    ACTS = %i[spend commit_offer].freeze

    # The two ceilings a fold can trip, and the Day ending under a quote that
    # already read it as open. Each is a rule this seam expresses as a refusal,
    # so a race that hits it in the database is turned back into that refusal
    # rather than surfacing as a fault. Anything else out of the database is a
    # fault, and is not caught.
    BUDGET_CEILING = /day_budgets_(preparation|exchange)_within_budget/
    DAY_ALREADY_CLOSED = /(docket_entries|committed_offers)_need_an_unclosed_day/
    # A Team commits at most one Offer a Day, and the unique index is what says
    # so. Two teammates pressing the same control is the ordinary case, so the
    # loser of that race gets the refusal rather than a fault.
    OFFER_ALREADY_COMMITTED = /UNIQUE constraint failed: committed_offers\.side_id/
    RACED_REFUSAL = Regexp.union(BUDGET_CEILING, DAY_ALREADY_CLOSED, OFFER_ALREADY_COMMITTED)

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

    # `details` is the act's own: `kind:` names the Action a `:spend` buys, and
    # `seconded_by:` names the teammate confirming a `:commit_offer` — nil where
    # the Instructor has waived the Second, which is the only other thing that
    # opens the gate.
    def initialize(act:, side:, day:, by:, **details)
      raise ArgumentError, "unknown act #{act.inspect}" unless ACTS.include?(act)

      @act = act
      @side = side
      @day = day
      @by = by
      @details = details
    end

    # A Quote is never nil, so `||=` memoizes it and assigning nil clears it.
    # `apply` clears it on a lost race and asks again.
    def quote
      @quote ||= build_quote
    end

    def apply
      raise Refused, quote if quote.refused?

      ActiveRecord::Base.transaction do
        # One row, and the trigger on it re-folds the half's spent counter. The
        # Budget's CHECK is underneath both, so a half pushed past its ceiling
        # by any insert path takes the insert down rather than going negative.
        entry = side.docket_entries.create!(
          day: day,
          lands_on_day: quote.landing_day,
          spent_by: by,
          case_action: action,
          cost: quote.cost,
          half: quote.half
        )
        # A lead time of zero lands the result on the Day it was bought, and
        # that Day's open has already happened. There is one landing seam, so
        # the spend calls it rather than materialising anything itself — and it
        # calls it for the whole Day rather than for this row, because landing
        # is idempotent and a seam narrowed to one caller's row is a second
        # path to keep true.
        Land.call(day) if quote.landing_day == day
        # The act's own work, inside the same transaction as the charge. A Team
        # is never charged for a play that half happened.
        perform(entry)
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless RACED_REFUSAL.match?(e.message)

      # A teammate spent, or the Day ended, between this quote and this insert.
      # Reads are not serialized, so both quotes can read the same half as
      # affordable — or the Day as open — and only the second insert finds the
      # ceiling or the closed Day. The database caught it; asking again turns it
      # back into the refusal a caller already knows how to render, rather than
      # a fault it does not.
      #
      # The Day is reloaded because the close landed on another connection and
      # the object this seam was handed still reads as open.
      # The draft is dropped with the quote: a teammate may have revised the
      # position in the same window, and the re-read has to see what is on the
      # table now rather than what was there when the quote was built.
      day.reload
      @quote = nil
      @staged_offer = nil
      raise Refused, quote if quote.refused?

      # The half moved back under the ceiling, or the Day reopened, between the
      # failed insert and the re-read. Nothing releases Budget and nothing
      # reopens a Day, so this should not happen; say so with the original fault
      # rather than a Refused carrying an affordable quote.
      raise
    end

    private

    attr_reader :act, :side, :day, :by, :details

    # The authored Action this act spends on, and nil for the Offer commit,
    # which is a Boardroom act rather than a menu entry. A kind the Case does
    # not author is a caller with a menu the engine never offered, not a refusal
    # a student should see.
    def action
      return nil unless act == :spend

      @action ||= side.case_version.actions.find_by(kind: details.fetch(:kind)) ||
        raise(ArgumentError, "#{details.fetch(:kind)} is not on this Case's Action menu")
    end

    # An Offer costs one point of the exchange half and lands the Day it is
    # made: there is no preparation to wait for.
    def cost = action ? action.cost : CommittedOffer::EXCHANGE_COST

    def half = action ? action.half : DayBudget::EXCHANGE

    def lead_time_days = action ? action.lead_time_days : 0

    def build_quote
      landing_day = landing_day_for
      return refusal(:the_result_would_land_past_the_last_day) if landing_day.nil?

      budget = side.budget_on(day)
      return refusal(:the_day_has_not_opened, landing_day: landing_day) if budget.nil?
      # Remaining Budget expires at close. The trigger underneath refuses the
      # insert either way; this is what turns it into a refusal a control can
      # render rather than a fault.
      return refusal(:the_day_has_closed, landing_day: landing_day) if day.closed?

      # The act's own rules, before the money. A Team that cannot commit is told
      # why rather than told the price.
      gate = gate_refusal
      return refusal(gate, landing_day: landing_day) if gate

      remaining_after = budget.remaining_in(half) - cost
      return refusal(:the_budget_cannot_cover_it, landing_day: landing_day) if remaining_after.negative?

      Quote.new(
        cost: cost,
        half: half,
        remaining_after: remaining_after,
        landing_day: landing_day,
        refusal: nil
      )
    end

    # What stands between the Side and the act, before its price is reached. A
    # spend off the menu has nothing here: it is ungated by design, which is why
    # every spend confirms instead.
    def gate_refusal
      return nil unless act == :commit_offer
      return :there_is_no_offer_on_the_table if staged_offer.nil?
      return :an_offer_has_already_been_committed_today if side.committed_offer_on(day)

      # The waiver-or-Second gate, which spans the roster, the Day and the
      # Instructor's waivers and so lives in Ruby — see `Second`.
      return nil if Second.satisfied?(
        side: side, day: day, taken_by: staged_offer.staged_by, seconded_by: seconded_by
      )

      :the_offer_has_not_been_seconded
    end

    def staged_offer = @staged_offer ||= side.staged_offer_on(day)

    def seconded_by = details[:seconded_by]

    def refusal(reason, landing_day: nil)
      Quote.new(
        cost: cost,
        half: half,
        remaining_after: nil,
        landing_day: landing_day,
        refusal: reason
      )
    end

    # A lead time of zero lands the result on the Day it was bought. Past the
    # last Day there is no Day to land on, and burning points on discovery that
    # can never arrive is what the refusal exists to prevent.
    def landing_day_for
      day.simulation.days.find_by(ordinal: day.ordinal + lead_time_days)
    end

    # A spend is done once its row is on the Docket. An Offer commit still has
    # its position to copy and the Day it implies to commit, and both belong in
    # the charge's own transaction.
    def perform(entry)
      return entry unless act == :commit_offer

      committed = commit_the_offer
      # An Offer commit implies the Day commit, and the reverse does not follow.
      # This is that direction, and it runs after the Offer is on the table: the
      # Day commit may be the second one and close the Day underneath us.
      Commit.call(side: side, day: day, by: by)
      committed
    end

    # The staged Offer is copied rather than moved. It stays on the Team's own
    # table as the record of what it held — and as the `offer_staged` line the
    # Docket folds from it, which destroying the draft would erase.
    def commit_the_offer
      committed = CommittedOffer.create!(
        side: side,
        day: day,
        staged_by: staged_offer.staged_by,
        seconded_by: seconded_by,
        note: staged_offer.note
      )
      staged_offer.offer_terms.each do |term|
        committed.offer_terms.create!(case_term: term.case_term, amount_cents: term.amount_cents)
      end
      committed
    end
  end
end
