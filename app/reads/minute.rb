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
      letterhead: letterhead,
      lines: sides.map { |side| line(side) }
    }
  end

  private

  attr_reader :simulation, :day, :you, :refused

  # Plaintiff first, which is the order the caption of any matter is written in
  # — not the order the rows came back in, and not alphabetical, which would put
  # the defendant on top for no reason a reader could name.
  def sides
    by_role = simulation.sides.index_by(&:role)
    [Side::PLAINTIFF, Side::DEFENDANT].filter_map { |role| by_role[role] }
  end

  # The Section rather than the matter. An Instructor runs a Section and reads
  # this in one; the matter is on the Sides' own paper, where the dispute is.
  def letterhead
    {
      section: simulation.section.name,
      matter: simulation.case_version.case.name,
      day: day.ordinal,
      of: simulation.days.count,
      in_fiction_date: day.in_fiction_date.to_s,
      closed: day.closed?,
      you: you.name
    }
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
      drawn: drawn?(side),
      granted: waiver && {
        by: waiver.granted_by.name,
        at: waiver.created_at.iso8601
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
