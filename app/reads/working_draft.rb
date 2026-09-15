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
  # The marks the whole register makes the same way — a figure, a Term's label,
  # a document, a Docket line, the back of the file, the Client's face at the
  # one size it is served at. #367 gave the game a second page composer, and two
  # copies of a decision are two decisions. See `Typeset`.
  include Typeset

  def self.for(...) = new(...)

  # `refused` is the spend that did not happen, carried back from the request
  # that tried it: the Action's kind and the engine's own refusal symbol. It is
  # an argument rather than something folded for, because a refusal writes
  # nothing — there is no row anywhere that remembers it, and that is the point.
  #
  # `draft_refused` is the same thing for a staging that did not happen, and it
  # is a second argument rather than a second field on the first because the two
  # land in different places on the page: a spend's refusal stamps the Action
  # line it was refused on, and a staging's has no line — it belongs to the
  # sheet. It carries a bare reason, since there is only ever one draft to
  # refuse and naming it would be naming the only one there is.
  #
  # `commit_refused` is the third, and it is a third rather than sharing the
  # staging's because the two belong to different parts of the instrument: a
  # staging's refusal is the sheet's and a commit's is the countersignature
  # block's, which is the control that was pressed. It also has to survive a
  # state the other two never meet — a commit refused *because* a teammate's
  # landed first leaves the block a record, with no quote left to carry a
  # sentence — so it is rendered there whether or not there is an execution to
  # price.
  #
  # `acceptance_refused` is the fourth, and it is a fourth for the reason the
  # third was a third: it lands somewhere else. The acceptance block is the
  # other Side's paper on this page, and it is the only part of the instrument
  # that can say what happened to an act taken on it.
  def initialize(side, day:, you:, refused: nil, draft_refused: nil, commit_refused: nil,
    acceptance_refused: nil)
    @side = side
    @day = day
    @you = you
    @refused = refused
    @draft_refused = draft_refused
    @commit_refused = commit_refused
    @acceptance_refused = acceptance_refused
  end

  def to_props
    {
      letterhead: letterhead,
      front_matter: front_matter,
      term_sheet: term_sheet,
      clipped: clipped,
      countersignature: countersignature,
      acceptance: acceptance,
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
  attr_reader :side, :day, :you, :refused, :draft_refused, :commit_refused,
    :acceptance_refused

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
      landed_empty_state: briefing.landed_empty_state,
      served: briefing.served.map { |entry| document(entry) },
      served_empty_state: briefing.served_empty_state,
      what_you_start_with: briefing.what_you_start_with.map { |entry| document(entry) },
      what_you_start_with_empty_state: briefing.what_you_start_with_empty_state,
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
  # `writable` is whether the sheet carries inputs at all — see `may_draft?`. It
  # sits beside `ours_staged` rather than replacing it: one says whether there is
  # a live draft, the other whether a new one may be written, and on the Day a
  # Team commits they part company.
  #
  # `note` is the staged Offer's own and does not carry forward from the last
  # committed one, which is the one place the sheet does not pre-fill from
  # `TermsBoard#ours`. A note is a covering line rather than a position — the
  # defendant's reads *open for acceptance today* — so yesterday's would restate
  # a deadline that has passed as though it were still standing.
  def term_sheet
    {
      empty_state: terms.empty_state,
      note: staged&.note,
      ours_staged: open_draft?,
      writable: may_draft?,
      tracks: terms.tracks.map do |track|
        {
          term: track.term,
          label: label_for(track.term),
          money: track.money?,
          ours: position(track.ours),
          theirs: position(track.theirs),
          aspiration: position(track.aspiration),
          on_the_table: track.on_the_table?,
          draft: drafted(track)
        }
      end,
      refusal: refusal_sentence(draft_refused)
    }
  end

  # What the inputs open holding: the position `TermsBoard` already prints in the
  # `ours` column, which is the draft on the table if there is one and otherwise
  # the last Offer this Team committed. A Team's negotiating position is what it
  # last put in front of the other Side, so opening empty would make every Day's
  # first act retyping yesterday — and a blank sheet reads as *we have withdrawn*,
  # which is a position nobody took.
  #
  # `amount` belongs to the money Term alone, which is what `StagedOfferTerm`
  # validates, and it is the **printed** figure rather than a raw one — the same
  # string the `ours` column above carries, currency symbol and separators
  # included.
  #
  # That is the register and not a convenience. #373 settled this sheet as print,
  # and a figure typed onto the ruled line beside a printed one it is being
  # measured against cannot be typeset differently from it without the line
  # reading as two documents. So there is one currency decision, `money`, and the
  # field opens holding its answer; what a student types over it is their own
  # hand, and the controller strips the symbol back off at the boundary. A
  # position that lands is printed again on the way back, which is what a working
  # draft does to a figure written on it.
  def drafted(track)
    {
      on: !track.ours.nil?,
      amount: (track.money? && track.ours) ? money(track.ours.amount_cents) : nil
    }
  end

  # Whether a position may still be written on this Day — the three things
  # `Offers::Stage` refuses, asked ahead of the press rather than after it. A
  # sheet that withdraws its inputs and a seam that refuses the write are the
  # same rule at two distances: the affordance is gone before the reader reaches
  # for it, and a page that went stale between the render and the press is still
  # refused rather than landing.
  #
  # The last of the three is what keeps inputs off an executed instrument, which
  # is a record rather than a working surface — and `Offers::Stage` holds it too,
  # because `TermsBoard#ours` prefers the draft to the committed Offer and a
  # revision landing there would print terms over two countersignatures that
  # never signed them.
  def may_draft? = committed.nil? && !day.closed? && !day.simulation.settled?

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
      may_sign: open_draft? ? signatories(staged.staged_by) : [],
      executed: !committed.nil?,
      # How this instrument landed, or — before it has — whether the gate is
      # open. The two are one question asked at two moments, and the *committed*
      # row is the authority wherever there is one: a Team that was granted a
      # waiver and had a teammate sign anyway executed under the signature, and
      # the record has to name them rather than the waiver they did not use.
      #
      # Before the commit there is no row to ask, and the answer is the ledger's.
      # Without this the block goes quiet the moment the waiver lands — the
      # refusal disappears and the control comes alive under a dashed line still
      # captioned *countersigned by*, which is now a line nobody will ever sign.
      # That is the one beat of this act the reader has to be told rather than
      # left to infer from an absence.
      waived: committed ? committed.seconded_by.nil? : side.second_waived_on?(day),
      execution: execution,
      # Beside `execution` rather than inside it, because it outlives it: the
      # refusal a two-tab race actually produces is a teammate's commit landing
      # first, which makes this block a record and `execution` nil on the very
      # read that has to say so.
      refusal: refusal_sentence(commit_refused)
    }
  end

  # What executing this draft would cost, and what stands in the way. Both, at
  # once: on a Side of one the price is real and the refusal is permanent, and
  # *this would take your whole exchange half, and you cannot execute it alone*
  # is the beat — either half on its own is not.
  #
  # It reaches `Days::Command.quote` directly rather than through a read, for the
  # reason `ActionBoard` reaches it: the seam already computes what a control
  # needs and writes nothing doing it, and a second path to the price is a second
  # place for it to disagree with what a Team is actually charged. It is not *on*
  # the Action Board, because a commit is executing a draft rather than buying a
  # menu entry — the distinction `docket_entries.case_action_id` is nullable for.
  #
  # `seconded_by: nil` asks the question the block's own control asks: may this
  # be executed as things stand, with nobody named. A Side with teammates gets
  # the same refusal and the block names them on the line beneath.
  #
  # **The sentence is always owed and the price is not.** A dead control that
  # will not say why is what #363 ruled out, so a block with nothing drawn still
  # carries its reason — but not a figure: a price for a position that does not
  # exist is a number with nothing under it, and `cost` there is the bare point
  # an Offer costs before anyone has decided what rides it.
  #
  # Nil only once the draft is executed. The block is a record then, both lines
  # filled and nobody left to sign, so there is neither a price nor an obstacle
  # to name.
  def execution
    return nil unless committed.nil?

    quote = Days::Command.quote(
      act: :commit_offer, side: side, day: day, by: you, seconded_by: nil
    )

    {
      cost: staged && quote.cost,
      half_label: staged && half_label(quote.half),
      # What the half has left afterwards, for the confirmation the block opens
      # before it charges — the same three facts a spend's stub carries. It is
      # nil on a refused quote because there is no negative Budget to render,
      # which is also every state in which no confirmation can be opened.
      remaining_after: quote.remaining_after,
      refusal: refusal_sentence(quote.refusal)
    }
  end

  # **The other Side's paper, and the one act taken on it.** An Acceptance is a
  # countersignature on their instrument, and #373 settled that their instrument
  # reaches this page as a strike through our own line and in no other form — it
  # is not in the Case File, which answers what we know, and not in the front
  # matter, which is what arrived. So there is nothing here shaped like their
  # paper to sign, and this block is what gives it one: it names the instrument
  # the strike column was folded from and carries the control.
  #
  # It names it and never restates it. The terms are the strike column above,
  # and a block reprinting them would put one position in two places and make
  # the reader compare them — the defect #373 removed and #365 was corrected for
  # reintroducing. `TermsBoard#their_offer` is the same row the column folds, so
  # the two cannot name different Offers.
  #
  # It also prints their covering note, which until now nothing did. The
  # defendant's reads *Without prejudice. Open for acceptance today.* and the
  # Day it says that of is over by the time it can be taken, which is the
  # register telling the reader a deadline passed rather than a line of copy
  # about one.
  #
  # **Nil where there is nothing across the table.** Unlike the countersignature
  # block this is not a permanent fixture: that block is about a draft the Team
  # could always draw, and its empty signature line is the lesson. There is no
  # lesson in a control for paper nobody has served, so the gate is the same one
  # `Clipped` uses — the thing exists or the rail is absent.
  def acceptance
    offer = terms.their_offer
    return nil if offer.nil?

    {
      day: offer.day.ordinal,
      drawn_by: offer.staged_by.name,
      note: offer.note,
      # Named by the Day it was committed on rather than by its row id: one
      # Offer per Side per Day by unique index, and the ordinal survives the
      # `demo:seed` reset that moves every id underneath it. It is also what
      # makes the press unambiguous — he accepts the instrument he read, even if
      # a newer one has since landed, which is legal play rather than a race:
      # an Offer stands on the table until it is taken or the run ends.
      committed_on: offer.day.ordinal,
      may_sign: signatories(you),
      refusal: refusal_sentence(acceptance_refusal),
      refused: refusal_sentence(acceptance_refused)
    }
  end

  # What the seam would refuse if this were pressed now, asked with the seconder
  # the control would actually send. Asking with `nil` instead would print *a
  # teammate has to countersign* under a control that would have landed, which
  # is the same class of defect as pricing an act against a Day the press does
  # not carry.
  def acceptance_refusal
    Offers::Accept.refusal_for(
      offer: terms.their_offer, side: side, day: day, by: you,
      seconded_by: side.seconders_other_than(you).first
    )
  end

  # The teammates who may countersign an act this reader takes, each with the
  # one thing about a person that survives a `demo:seed` reset. A name cannot be
  # posted back — two members could share one — and a row id moves, so the
  # identifier is the email, which is what `Demo::Seat` already keys the cast by.
  def signatories(taken_by)
    side.seconders_other_than(taken_by).map { |member| {name: member.name, email: member.email} }
  end

  # The Exhibits clipped to the draft, and the ones that could be — down the side
  # of the instrument, which is where `CONTEXT.md` § Register puts them.
  #
  # `available` is `CaseFile`'s own gate and the one thing on this whole surface
  # that gates: it reads *has this Team ever held a playable Exhibit*, so the
  # rail is absent on a Day 1 that has never seen one and permanent afterwards.
  # An affordance for a thing a Team has never held would teach a control that
  # does nothing; taking it away again once the Exhibit is spent would teach the
  # opposite.
  #
  # A spent Exhibit stays listed. The document is not spent — it stays in the
  # Case File as what the Team knows — and a row that vanished on being played
  # would read as a document lost rather than a card played.
  #
  # Documents are named by their authored identifier rather than by row id: it is
  # what `Offers::Stage` is reached with here, and it is stable across the
  # `demo:seed` reset that moves every id underneath it.
  def clipped
    {
      available: case_file.exhibits_available?,
      writable: may_draft?,
      documents: case_file.entries.select { |entry| entry.playable || entry.spent }
        .map do |entry|
          {
            identifier: entry.identifier,
            title: entry.title,
            spent: entry.spent,
            clipped: riding.include?(entry.identifier)
          }
        end
    }
  end

  # What is on the draft now. Empty where there is no draft, which is also every
  # Day before the Team has drawn one.
  def riding
    @riding ||= staged ? staged.exhibits.map { |filed| filed.case_document.identifier } : []
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

  def back = back_of_file(case_file, docket)

  def position(value)
    return nil if value.nil?
    return {amount: nil, money: false} unless value.money?

    {amount: money(value.amount_cents), money: true}
  end

  # One vocabulary, two surfaces: the slip's Action lines, the countersignature
  # block's price and the term sheet's own staging refusal all name a rule
  # `Days::Command` or `Offers::Stage` turned an act down by. The key sits at
  # `reads.refusals` rather than under the Board for that reason — see the
  # locale file.
  def refusal_sentence(refusal)
    refusal.presence && I18n.t("reads.refusals.#{refusal}")
  end
end
