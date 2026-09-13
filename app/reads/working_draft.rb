# frozen_string_literal: true

# The whole of a Day as one page, in the grammar #315 settled: the draft is the
# page. Front matter on top, the term sheet through the middle with the
# countersignature block beneath it, the Client's memo under that, the Action
# slip along the foot, and the Case File and the Docket on the back of the same
# instrument.
#
# It composes the reads rather than replacing any of them. Each of those answers
# one question and answers it in domain objects — a `Day`, a `User`, a refusal
# symbol, a Client's seed and expression — and this is the one place those
# become the flat, JSON-shaped thing a page is handed: Days reduced to ordinals,
# Users to names, money formatted once, every symbol the engine names a rule by
# given its sentence, and the Client's face composed at the one size the memo
# serves. Doing that inside the reads would make each of them a view; doing it
# in the controller would spread it across every screen that ever renders a Day.
#
# It is not itself a domain object and has no entry in `CONTEXT.md`. Nothing
# here decides anything: if a number or a sentence appears below, one of the
# reads or the Case authored it. The one thing it *chooses* is a render size,
# which exists nowhere else — see `portrait`.
class WorkingDraft
  # The one size the Consult memo's face is served at, of the three the part set
  # has been looked at in. A passport photograph clipped to a file is the
  # register's own idiom for a face on a legal memo, and it is the size #325
  # checked the stock set survives the halftone at.
  PORTRAIT_SIZE = 78

  def self.for(...) = new(...)

  # `refused` is the spend that did not happen, carried back from the request
  # that tried it: the Action's kind and the engine's own refusal symbol. It is
  # an argument rather than something folded for, because a refusal writes
  # nothing — there is no row anywhere that remembers it, and that is the point.
  def initialize(side, day:, you:, refused: nil)
    @side = side
    @day = day
    @you = you
    @refused = refused
  end

  def to_props
    {
      letterhead: letterhead,
      front_matter: front_matter,
      term_sheet: term_sheet,
      countersignature: countersignature,
      memo: memo,
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
  attr_reader :side, :day, :you, :refused

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

  # What the Client said, on the Day they were asked. The Consult is the one
  # Action that buys words rather than paper, so there is no Case File row for
  # it to land in and this is the whole of where it lands.
  #
  # **Today's only.** A `ConsultMemo` is re-readable forever — the band is
  # folded as of the spend's own row, so one read next week still says what was
  # said — but the front of the instrument is today's working state, and no
  # surface currently reaches a closed Day's words. The Docket keeps the band
  # after the Day, which is the carrier `CONTEXT.md` names under *Reaction
  # Band*; the wording is bought for the Day it was bought on.
  #
  # Newest first, because the reader is sent here by having just asked.
  def memo
    beats = side.consults(day: day).reverse.map(&:beat)

    {
      empty_state: beats.empty? ? I18n.t("reads.consult_memo.empty") : nil,
      portrait: beats.first && portrait(beats.first),
      entries: beats.map do |beat|
        {band: band_label(beat.band), line: beat.line}
      end
    }
  end

  # The face, printed **once** — on the newest Consult, whose expression is the
  # band that stands now. It is the one portrait in the game (ADR 0005), and
  # repeating it down a stack would be the same drawing several times and, since
  # `Portraits::Compose` scopes its screen ids to the seed, the expression and
  # the size, literally the same element ids several times.
  #
  # ADR 0008 binds the **read**: `ConsultMemo::Beat` hands on a seed and an
  # expression and never a rendered portrait, because a halftone screen is fixed
  # in ink on the page and a read has no business choosing a size. This layer is
  # where a size exists — the same act as formatting money once and giving a
  # refusal its sentence.
  #
  # Composed here rather than fetched from an endpoint of its own: the two inks
  # resolve through custom properties on an ancestor, and an SVG behind an
  # `<img>` cannot see the page it sits on — so the portrait would stop
  # following the paper, which is the whole of what ADR 0008 decided about ink.
  def portrait(beat)
    Portraits::Compose.call(
      seed: beat.portrait_seed, expression: beat.expression, size: PORTRAIT_SIZE
    )
  end

  # Every Action, priced, whether or not the half will cover it — with the
  # refusal's own sentence beside the ones that will not.
  #
  # A spend that was just refused is the same sentence on the same line, marked
  # as having happened: `refused_just_now` is the whole difference between an
  # Action he cannot afford and an Action he tried to buy a moment ago, which
  # re-rendering alone cannot say. There is one refusal vocabulary and this is
  # its second occasion, not a second vocabulary.
  #
  # The Entry's own refusal wins where there is one, because it was computed
  # against the Day as it stands now; the carried reason is the fallback for the
  # case the seam documents as impossible — a half that moved back under its
  # ceiling between the failed charge and this read — where the line would
  # otherwise carry a stamp with nothing under it.
  def slip
    {
      remaining: DayBudget::HALVES.to_h do |half|
        [half, {left: board.remaining_in(half), label: half_label(half)}]
      end,
      actions: board.entries.map do |entry|
        just_now = refused_kind == entry.kind

        {
          kind: entry.kind,
          label: kind_label(entry.kind),
          cost: entry.cost,
          half: entry.half,
          half_label: half_label(entry.half),
          lead_time_days: entry.lead_time_days,
          lands_today: entry.lands_today?,
          landing_day: entry.landing_day&.ordinal,
          remaining_after: entry.remaining_after,
          affordable: entry.affordable?,
          refused_just_now: just_now,
          refusal: refusal_sentence(entry.refusal || (just_now ? refused_reason : nil))
        }
      end
    }
  end

  def refused_kind = refused && refused["kind"]

  def refused_reason = refused && refused["reason"].presence

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
      band: entry.band && band_label(entry.band),
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

  # The band is a symbol the engine names a rule by, like a refusal and an
  # Action's kind, so it becomes text here and not on a page. One key serves the
  # memo and the Docket line both — see the locale file for why.
  def band_label(band) = I18n.t("reads.bands.#{band}")

  def kind_label(kind) = I18n.t("reads.action_board.kinds.#{kind}")

  def half_label(half) = I18n.t("reads.action_board.halves.#{half}")

  def refusal_sentence(refusal)
    refusal && I18n.t("reads.action_board.refusals.#{refusal}")
  end

  # A Term's key is authored per Case, so the engine has no sentence for it and
  # humanizes instead. The label belongs on the authored table — #343.
  def label_for(key) = key.humanize
end
