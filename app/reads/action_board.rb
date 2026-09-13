# frozen_string_literal: true

# The menu of what a Team could do this Day, each Action with its cost and its
# lead time. *What we could do* — opposite the Case File's *what we know* and
# the Docket's *what we have done*.
#
# Every Action is on it from Day 1, priced, whether or not the Team can afford
# it today: hiding what an Action costs makes the Budget unplannable, and
# planning the Budget is the lesson. An Action the half cannot cover is present
# and refused, with the reason, rather than absent.
#
# It reads through `Days::Command.quote` rather than off `case_actions`, because
# the seam already computes what a control needs — the price, the half, what is
# left today if it goes through, the Day the result lands, and the refusal — and
# writes nothing doing it. A second path to the same numbers is a second place
# for them to disagree with what a student is actually charged.
class ActionBoard
  # One Action, priced against this Side's Day. `remaining_after` is what the
  # half would still hold if this one went through, and it is nil on a refused
  # Entry for the same reason `Quote` carries none: there is no negative Budget
  # to render. It is what a confirmation is written from — the number that makes
  # a price a trade-off rather than a fact.
  Entry = Data.define(:kind, :cost, :half, :lead_time_days, :landing_day, :remaining_after,
    :refusal) do
    def affordable? = refusal.nil?

    # A lead time of zero lands the result on the Day it was bought.
    def lands_today? = lead_time_days.zero?
  end

  def self.for(...) = new(...)

  def initialize(side, day:)
    @side = side
    @day = day
  end

  # Cheapest first — the order `CaseVersion#actions` already reads in, and the
  # order a board is read in when the question is what today's half will cover.
  def entries
    @entries ||= menu.map do |action|
      # No member in particular. A price is the Team's, not a student's: the
      # half a spend draws on is shared, and every member has the same menu.
      quote = Days::Command.quote(act: :spend, side: side, day: day, by: nil, kind: action.kind)

      Entry.new(
        kind: action.kind,
        cost: action.cost,
        half: action.half,
        lead_time_days: action.lead_time_days,
        landing_day: quote.landing_day,
        remaining_after: quote.remaining_after,
        refusal: quote.refusal
      )
    end
  end

  # The Action Board is never empty — a Case that authored no menu could not be
  # played — so there is no empty state here. That is the point of it as
  # teaching: a full board on Day 1 is what says an Action costs something and
  # arrives later.
  def affordable = entries.select(&:affordable?)

  # What each half will still buy today. Read off `day_budgets` rather than
  # folded, because that row is ADR 0002's one materialized exception and the
  # authority for remaining — and the slip a student reads this on is the Action
  # Board itself, so a second read over the same row could only ever disagree
  # with the prices beside it.
  #
  # Nil before the Day has opened, which is the condition every Entry here is
  # refused under anyway.
  def remaining_in(half) = budget&.remaining_in(half)

  private

  attr_reader :side, :day

  def budget = @budget ||= side.budget_on(day)

  def menu = side.case_version.actions
end
