# frozen_string_literal: true

# The whole of a Day as one page, in the grammar #315 settled: the draft is the
# page. Front matter on top, the term sheet through the middle with the
# countersignature block beneath it, the Action slip along the foot, and the
# Case File and the Docket on the back of the same instrument.
#
# It composes the five reads rather than replacing any of them. Each of those
# answers one question and answers it in domain objects — a `Day`, a `User`, a
# refusal symbol — and this is the one place those become the flat, JSON-shaped
# thing a page is handed: Days reduced to ordinals, Users to names, money
# formatted once, and every symbol the engine names a rule by given its
# sentence. Doing that inside the five would make each of them a view; doing it
# in the controller would spread it across every screen that ever renders a Day.
#
# It is not itself a domain object and has no entry in `CONTEXT.md`. Nothing
# here decides anything: if a number or a sentence appears below, one of the
# five reads or the Case authored it.
class WorkingDraft
  def self.for(...) = new(...)

  def initialize(side, day:, you:)
    @side = side
    @day = day
    @you = you
  end

  def to_props
    {
      letterhead: letterhead,
      front_matter: front_matter,
      term_sheet: term_sheet,
      countersignature: countersignature,
      slip: slip,
      back: back
    }
  end

  private

  # `you` is who is reading, handed in rather than folded for. There is no
  # authentication yet, so the caller is the only thing that knows — and the
  # fold this replaces answered a different question. `Side#members` is the
  # roster, *who has acted for this Team*, and the two coincide only while
  # exactly one member has acted. They come apart at the cold open, where the
  # ledgers are empty and the player is sitting there all the same, and again
  # the moment a second act is attributed.
  attr_reader :side, :day, :you

  def briefing = @briefing ||= MorningBriefing.for(side, day: day)

  def board = @board ||= ActionBoard.for(side, day: day)

  def terms = @terms ||= TermsBoard.for(side, day: day)

  def case_file = @case_file ||= CaseFile.for(side)

  def docket = @docket ||= Docket.for(side)

  def staged = @staged ||= side.staged_offer_on(day)

  def committed = @committed ||= side.committed_offer_on(day)

  def letterhead
    {
      matter: side.case_version.case.name,
      role: side.role,
      day: day.ordinal,
      of: side.simulation.days.count,
      in_fiction_date: day.in_fiction_date.to_s,
      you: you.name
    }
  end

  def front_matter
    {
      landed: briefing.landed.map { |entry| document(entry) },
      served: briefing.served.map { |entry| document(entry) },
      what_you_start_with: briefing.what_you_start_with.map { |entry| document(entry) },
      opening_statement: briefing.opening_statement,
      calendar: briefing.calendar.map do |calendar_day|
        {ordinal: calendar_day.ordinal,
         in_fiction_date: calendar_day.in_fiction_date.to_s,
         closed: calendar_day.closed?,
         today: calendar_day.ordinal == day.ordinal}
      end,
      rubric: {dimensions: briefing.rubric.dimensions, bonus: briefing.rubric.bonus},
      grammar: briefing.grammar_line
    }
  end

  # Our column, theirs, and the Client's aspiration in the margin.
  #
  # `ours_staged` is what makes our column a draft rather than a position
  # already taken, and the sheet carries it once rather than on every Track:
  # `TermsBoard` answers it per Track because a Track is what it returns, but
  # the answer is the sheet's — one Offer is staged or it is not — and seven
  # copies of one boolean is seven chances for a page to read the wrong one.
  def term_sheet
    {
      empty_state: terms.empty_state,
      note: staged&.note,
      ours_staged: open_draft?,
      tracks: terms.tracks.map do |track|
        {
          term: track.term,
          label: label_for(track.term),
          ours: position(track.ours),
          theirs: position(track.theirs),
          aspiration: position(track.aspiration),
          on_the_table: track.on_the_table?
        }
      end
    }
  end

  # One line signed and one blank naming the teammates who may sign it, per
  # `CONTEXT.md` § Second — permanently, whether or not there is a draft under
  # it, because an empty block is how the Day teaches that a commit needs a
  # second hand. On a Side of one the blank names nobody and the control is
  # inert, which is the lesson rather than an error.
  #
  # Once the Day's Offer is committed the block is a record rather than an
  # invitation: it reads off `committed_offers`, both lines filled, and nobody
  # may sign a thing that is already executed. A commit through an Instructor's
  # waiver has no seconder at all, so `waived` is what keeps the second line
  # from rendering as though it were still blank.
  def countersignature
    offer = committed || staged

    {
      drawn_by: offer&.staged_by&.name,
      signed_by: committed&.seconded_by&.name,
      may_sign: open_draft? ? side.seconders_other_than(staged.staged_by).map(&:name) : [],
      executed: !committed.nil?,
      waived: !committed.nil? && committed.seconded_by.nil?
    }
  end

  def open_draft? = !staged.nil? && committed.nil?

  # Every Action, priced, whether or not the half will cover it — with the
  # refusal's own sentence beside the ones that will not.
  def slip
    {
      remaining: DayBudget::HALVES.to_h do |half|
        [half, {left: board.remaining_in(half), label: half_label(half)}]
      end,
      actions: board.entries.map do |entry|
        {
          kind: entry.kind,
          label: kind_label(entry.kind),
          cost: entry.cost,
          half: entry.half,
          half_label: half_label(entry.half),
          lead_time_days: entry.lead_time_days,
          lands_today: entry.lands_today?,
          landing_day: entry.landing_day&.ordinal,
          affordable: entry.affordable?,
          refusal: refusal_sentence(entry.refusal)
        }
      end
    }
  end

  # What we know, and what we have done — under one heading, because the back
  # of the instrument is one surface.
  def back
    {
      case_file: {
        empty_state: case_file.empty_state,
        documents: case_file.entries.map { |entry| document(entry) }
      },
      docket: {
        empty_state: docket.empty_state,
        entries: docket.entries.map { |entry| docket_line(entry) }
      }
    }
  end

  def document(entry)
    {
      identifier: entry.identifier,
      title: entry.title,
      body: entry.body,
      day: entry.day.ordinal,
      # A symbol survives to the page as a string, so it is made one here: what
      # a spec asserts on and what the page reads have to be the same value.
      arrival: entry.arrival.to_s,
      served: entry.served?,
      playable: entry.playable,
      spent: entry.spent,
      at_the_open: entry.at_the_open?
    }
  end

  def docket_line(entry)
    {
      at: entry.at.iso8601,
      act: entry.act.to_s,
      act_label: act_label(entry),
      by: entry.by&.name,
      day: entry.day&.ordinal,
      kind: entry.kind,
      cost: entry.cost,
      half: entry.half,
      half_label: entry.half && half_label(entry.half),
      band: entry.band,
      lands_on_day: entry.lands_on_day&.ordinal,
      spend: entry.spend?,
      instructor_action: entry.instructor_action?
    }
  end

  # A spend is named by the Action it bought; the three acts with no cost are
  # named by the act, because there is no Action behind them to name.
  def act_label(entry)
    entry.spend? ? kind_label(entry.kind) : I18n.t("reads.docket.acts.#{entry.act}")
  end

  def position(value)
    return nil if value.nil?
    return {amount: nil, money: false} unless value.money?

    {amount: money(value.amount_cents), money: true}
  end

  # Whole dollars where the amount is whole, which every authored figure so far
  # is. Formatted here rather than in the page: one currency decision, and the
  # page has nothing to compute.
  def money(cents)
    ActiveSupport::NumberHelper.number_to_currency(
      cents / 100.0, precision: (cents % 100).zero? ? 0 : 2
    )
  end

  def kind_label(kind) = I18n.t("reads.action_board.kinds.#{kind}")

  def half_label(half) = I18n.t("reads.action_board.halves.#{half}")

  def refusal_sentence(refusal)
    refusal && I18n.t("reads.action_board.refusals.#{refusal}")
  end

  # A Term's key is authored per Case, so the engine has no sentence for it and
  # humanizes instead. The label belongs on the authored table — #343.
  def label_for(key) = key.humanize
end
