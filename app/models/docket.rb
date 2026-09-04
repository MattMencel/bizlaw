# frozen_string_literal: true

# The Team's chronological record: what was spent, which member spent it, the
# Day its result lands, and the two things that happen on a Day without a cost.
#
# It is a fold over three ledgers rather than one table, because only one of
# them is a spend. `docket_entries` carries `CHECK (cost >= 1)` and points at an
# authored Action, so a staging — which costs nothing, because nothing has been
# spent — could not be one of its rows even if the design wanted it to be, and
# neither could an Instructor's waiver. What the Docket owes them is that they
# are *visible*: a staging surfaces in a teammate's next Morning Briefing, and a
# waiver is on the record as an Instructor action rather than as a silent
# change in what a control will do.
#
# It carries no per-member totals and no contribution scores. A shared record
# that ranks the people in it is a leaderboard, which is not what a Docket is.
class Docket
  SPEND = :spend
  OFFER_STAGED = :offer_staged
  SECOND_WAIVED = :second_waived

  # One line of the record. `cost`, `half` and `lands_on_day` are the spend's
  # and are nil on the two acts that have none — which is the distinction the
  # Docket is making, so it is left visible rather than filled with zeroes.
  Entry = Data.define(:at, :act, :by, :day, :cost, :half, :lands_on_day) do
    def spend? = act == SPEND

    def instructor_action? = act == SECOND_WAIVED
  end

  def self.for(...) = new(...).entries

  def initialize(side, day: nil)
    @side = side
    @day = day
  end

  # In the order it was written. Seen forward it is the Team's calendar, because
  # every spend names the Day its result lands on.
  def entries
    (spends + stagings + waivers).sort_by { |entry| [entry.at, entry.act.to_s] }
  end

  private

  attr_reader :side, :day

  def spends
    scoped(side.docket_entries).map do |entry|
      Entry.new(
        at: entry.created_at,
        act: SPEND,
        by: entry.spent_by,
        day: entry.day,
        cost: entry.cost,
        half: entry.half,
        lands_on_day: entry.lands_on_day
      )
    end
  end

  # The staging, at the time it was staged, attributed to whoever put the
  # position now on the table there. A revision costs nothing and adds no line;
  # it moves the attribution, because that is who a teammate reading this would
  # be seconding.
  def stagings
    scoped(side.staged_offers).map do |offer|
      line(at: offer.created_at, act: OFFER_STAGED, by: offer.staged_by, day: offer.day)
    end
  end

  def waivers
    scoped(side.second_waivers).map do |waiver|
      line(at: waiver.created_at, act: SECOND_WAIVED, by: waiver.granted_by, day: waiver.day)
    end
  end

  def line(at:, act:, by:, day:)
    Entry.new(at: at, act: act, by: by, day: day, cost: nil, half: nil, lands_on_day: nil)
  end

  def scoped(relation) = day.nil? ? relation : relation.where(day: day)
end
