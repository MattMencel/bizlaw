# frozen_string_literal: true

# What a Day opens with, over the Firm's table: the Actions that have just
# landed and any documents the other Side served, beside what the Team started
# with — the documents in hand at the open, the Client's opening statement, the
# calendar and the published Rubric.
#
# On Day 1 what-you-start-with is the only non-empty section, because nothing
# has landed and nothing has been served yet. On later Days it is what a
# returning teammate is caught up on.
#
# Every section is composed by the engine from objects the Case already authors,
# so a briefing is never authored per Case — and it is composed **on read**,
# with no row of its own. Per ADR 0004 that is what lets one object serve both
# callers: the same briefing widened over the Days a teammate missed is the same
# fold over a wider range, and a row written at the Day's close could only ever
# have answered one of the two.
#
# The widening is `since:` and never a per-student record. There is no
# per-student progress state anywhere in the design, and deriving the range from
# Attribution would reinvent it — a teammate who deliberated all week but spent
# nothing would read as absent.
class MorningBriefing
  # One Day of the Simulation's calendar. The whole calendar rather than what is
  # left, because an Action's lead time is only plannable against how many Days
  # there are.
  CalendarDay = Data.define(:ordinal, :in_fiction_date, :closed) do
    def closed? = closed
  end

  # The published Rubric, as fixed interface copy. It is published to students
  # in full on day one, so it is the one thing here that names the grade — and
  # it names only the dimensions and their weights, never a number about this
  # Team. No rubric-derived figure reaches a student before Release.
  Rubric = Data.define(:dimensions, :bonus)

  def self.for(...) = new(...)

  # `since` is the earliest Day this briefing covers, and defaults to the Day
  # itself. A teammate returning from two Days away is handed the same object
  # over the Days they missed; which Days those are is the caller's to say.
  def initialize(side, day:, since: nil)
    @side = side
    @day = day
    @since = since || day
  end

  # What the Actions this Team bought have just produced, read off the **Docket**
  # rather than off the Case File row's Day.
  #
  # The row's Day is when the Team first came to know the document, and it never
  # moves again — so a document served on Day 3 and then found on Day 5 keeps
  # `day = 3` while `Days::Land` clears its `served_at`, and it would fall out
  # of Day 3's served section and Day 5's landed section both, appearing in no
  # narrow briefing at all. The Docket is append-only and every spend names the
  # Day its result lands on, which is the question this section is asking.
  def landed
    @landed ||= landed_identifiers.filter_map { |identifier| held[identifier] }
  end

  # What the other Side put in front of this Team. Playing an Exhibit is serving
  # it, so this is where a Team learns it has been argued at — and never what
  # the argument was worth, which is a Reaction Band bought with an Action.
  def served
    @served ||= in_range.select(&:served?)
  end

  # The documents in hand at the open, drawn from Provenance. Always present,
  # whatever Day this is: on Day 1 it is the only section with anything in it,
  # and on later Days it is what a returning teammate is caught up on.
  def what_you_start_with
    @what_you_start_with ||= case_file.entries.select { |entry| started_with?(entry) }
  end

  # What this Team's own Client said they want, on the Day the Team first sat
  # down. Authored prose, never generated: it is an object in the dispute rather
  # than a line about something the engine computed.
  def opening_statement = side.client.opening_statement

  def calendar
    @calendar ||= side.simulation.days.order(:ordinal).map do |simulation_day|
      CalendarDay.new(
        ordinal: simulation_day.ordinal,
        in_fiction_date: simulation_day.in_fiction_date,
        closed: simulation_day.closed?
      )
    end
  end

  def rubric
    Rubric.new(
      dimensions: I18n.t("reads.morning_briefing.rubric.dimensions"),
      bonus: I18n.t("reads.morning_briefing.rubric.bonus")
    )
  end

  # Where the two-room grammar is named, in one line of fixed interface copy. A
  # room is never empty, so no room's own state can carry it — and it describes
  # the machine rather than the dispute, which is why it is neither authored per
  # Case nor generated.
  def two_room_line = I18n.t("reads.morning_briefing.two_rooms")

  # The Days this briefing covers, in order. One on an ordinary morning, and as
  # many as a returning teammate missed.
  def days = (since.ordinal..day.ordinal)

  private

  attr_reader :side, :day, :since

  def case_file = @case_file ||= CaseFile.for(side)

  def in_range
    @in_range ||= case_file.entries.select { |entry| days.cover?(entry.day.ordinal) }
  end

  # The documents the Actions landing in this range yield, in the order those
  # Actions were bought. An Offer commit names no Action and yields nothing.
  def landed_identifiers
    side.docket_entries
      .joins(:lands_on_day).where(days: {ordinal: days})
      .includes(case_action: :documents)
      .flat_map { |entry| entry.case_action&.documents&.map(&:identifier) || [] }
      .uniq
  end

  def held = @held ||= case_file.entries.index_by(&:identifier)

  # What a Team walked in with is a Provenance, not a date. An Action with no
  # lead time bought on Day 1 lands on Day 1 as well, and that is news.
  def started_with?(entry) = entry.at_the_open?
end
