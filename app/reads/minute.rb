# frozen_string_literal: true

# The Instructor's own instrument: the record of the one act they take inside a
# running Day.
#
# `CONTEXT.md` § Instructor lists their powers over a running Simulation as
# deliberately few, and of those this surface carries exactly one — the waiver
# of a Second, granted to one Team for one Day. It is not a console. There is no
# force-close here, no deadline, no Event, and nothing that reads a Team's
# papers: #312 ruled a console out on the grounds that a second tab makes one
# unnecessary, and a page that grew the other powers would be that console
# arriving by increment.
#
# It is drawn in the register like everything else, because #366 settled that
# the Instructor's paper is paper too — but it is **their** paper and not the
# Team's. They are not in the dispute, so there is no matter in the letterhead's
# first position, no term sheet, no half and no Client. What there is is a
# minute: the Section, the Day, and one ruled line per Side.
#
# **No signature line anywhere on it.** A block modelled on the countersignature
# it releases is the obvious drawing and the wrong one — `CONTEXT.md` § Second
# is explicit that the Instructor never Seconds on a Team's behalf, because
# Attribution would then name someone who did not take the position, and an
# instrument that invites them to sign says the opposite in the loudest register
# available.
#
# Like `WorkingDraft` it is the layer where domain objects become the flat,
# JSON-shaped thing a page is handed, and it decides nothing: a Side is named by
# its role, a Day by its ordinal, a person by their name. Unlike `WorkingDraft`
# it folds no other read, because there is no question here big enough to have
# one — what a waiver line says is a row's existence and the two facts hanging
# off it.
class Minute
  # The register's marks — an in-fiction date, a role, a surface's copy. The
  # Minute prints no Term and no figure, so it reaches for few of them.
  include Typeset

  def self.for(...) = new(...)

  # `you` is who is reading, handed in for the reason `WorkingDraft` takes it:
  # there is no authentication, so the caller is the only thing that knows. Here
  # it is always the Instructor, who is on no Side at all — which is why this
  # takes a Simulation rather than one.
  #
  # `refused` is the grant that did not happen, carried back from the request
  # that tried it: the Side's role and the engine's own refusal symbol. It is an
  # argument for the reason `WorkingDraft`'s is — a refusal writes nothing, and
  # there is no row anywhere that remembers it.
  def initialize(simulation, day:, you:, refused: nil)
    @simulation = simulation
    @day = day
    @you = you
    @refused = refused
  end

  def to_props
    {
      copy: copy("reads.minute"),
      letterhead: letterhead,
      settled: settled,
      lines: settled ? [] : sides.map { |side| line(side) }
    }
  end

  private

  attr_reader :simulation, :day, :you, :refused

  # The matter ended, and with it the one act this page is for.
  #
  # A settled run has no Day being played — `Days::Close` opens nothing after an
  # Acceptance — so there is nothing to grant a waiver on and no position that
  # could still be executed. Without this the minute renders the first *unclosed*
  # Day, which after a settlement is one `Simulations::Create` laid down and
  # `Days::Open` never reached: the professor's own tab would print a live
  # tomorrow with two empty ruled lines, asserting the game was still going one
  # gesture after the ending.
  #
  # It stays the minute rather than becoming the instrument. The executed
  # agreement is the Teams' paper and this page has never read their file; what
  # an Instructor is owed here is the one line that says their powers over this
  # run are spent.
  # `defined?` rather than `||=`: the answer is nil for the whole of every run
  # that has not settled, which is every run until its last act, and `||=` would
  # ask the database again for each of the three slots that read it.
  def settled
    return @settled if defined?(@settled)

    @settled = if simulation.settled?
      struck = simulation.settlement.day
      {day: struck.ordinal,
       in_fiction_date: in_fiction(struck.in_fiction_date),
       closed: I18n.t("reads.minute.closed.body",
         day: struck.ordinal, date: in_fiction(struck.in_fiction_date))}
    end
  end

  # Plaintiff first, which is the order the caption of any matter is written in
  # — not the order the rows came back in, and not alphabetical, which would put
  # the defendant on top for no reason a reader could name.
  def sides
    by_role = simulation.sides.index_by(&:role)
    [Side::PLAINTIFF, Side::DEFENDANT].filter_map { |role| by_role[role] }
  end

  # The Section rather than the matter. An Instructor runs a Section and reads
  # this in one; the matter is on the Sides' own paper, where the dispute is.
  # The Day goes once the matter has settled, for the reason the Sides' own
  # letterhead drops it: the *of ten* is a clock, and printing an ordinal out of
  # a calendar nobody will reach again invites the reader to ask what happens on
  # the Day after. What the ending is dated by is `settled` above.
  def letterhead
    {
      section: simulation.section.name,
      matter: simulation.case_version.case.name,
      title: title,
      day: settled ? nil : day.ordinal,
      of: simulation.days.count,
      day_of: settled ? nil : day_of(day.ordinal, simulation.days.count),
      in_fiction_date: settled ? nil : in_fiction(day.in_fiction_date),
      closed: day.closed?,
      matter_line: matter_line,
      you: you.name
    }
  end

  def title
    return I18n.t("reads.minute.title.settled") if settled

    I18n.t("reads.minute.title.sitting", day: day.ordinal)
  end

  # The matter, and where this run stands in it.
  def matter_line
    matter = simulation.case_version.case.name
    return I18n.t("reads.minute.matter.settled", matter: matter, day: settled[:day]) if settled

    I18n.t("reads.minute.matter.#{day.closed? ? :closed : :sitting}",
      matter: matter, day: day.ordinal, of: simulation.days.count)
  end

  # One Side's line. `drawn` is the one fact about a Team this page carries and
  # it is deliberately the thinnest one there is: *this Team has a position on
  # the table that nobody has executed*. Granting blind is pressing a control
  # with no way of knowing whether it does anything, and the professor watching
  # should be able to see why the waiver is being granted now — but anything
  # past that is the Team's file, which is not the Instructor's to read from
  # here.
  #
  # `granted` is a record rather than a state: there is no revoking a waiver —
  # `Offers::WaiveSecond` has no such verb and `CONTEXT.md` § Instructor does not
  # list one among the powers — so once this is filled the line stops being a
  # control and starts being the minute of something that happened.
  def line(side)
    waiver = side.second_waivers.find_by(day: day)

    {
      role: side.role,
      role_label: role_label(side.role),
      drawn: drawn?(side),
      state: I18n.t("reads.minute.waivers.#{drawn?(side) ? :drawn : :undrawn}"),
      waive_label: I18n.t("reads.minute.waivers.waive_label", role: role_label(side.role)),
      # Formatted here rather than by the browser, so the minute reads the same
      # to everyone who opens it. There is no Instructor's time zone yet, so it
      # is the app's.
      granted: waiver && {
        by: waiver.granted_by.name,
        minuted: I18n.t("reads.minute.waivers.granted",
          name: waiver.granted_by.name, at: I18n.l(waiver.created_at, format: :minuted))
      },
      refusal: refusal_sentence(refused_reason_for(side))
    }
  end

  def refused_reason_for(side)
    refused && (refused["role"] == side.role) && refused["reason"].presence
  end

  # The same vocabulary the draft reads refusals out of, because it is the same
  # engine turning the act down: a Day that has closed says one thing, and it
  # says it identically on a student's slip and on the Instructor's minute.
  def refusal_sentence(refusal)
    refusal.presence && I18n.t("reads.refusals.#{refusal}")
  end

  # A position on the table with nobody's countersignature under it, which is
  # the only state a waiver changes anything in. A Team that has executed today
  # is past the gate and a Team with nothing drawn has not reached it.
  def drawn?(side) = !side.staged_offer_on(day).nil? && side.committed_offer_on(day).nil?
end
