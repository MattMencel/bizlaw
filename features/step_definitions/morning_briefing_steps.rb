# frozen_string_literal: true

# The reads a Day is played from. Every one of them is a fold that writes
# nothing, so a step here only ever asks a question.
def a_briefing(ordinal, since: nil)
  MorningBriefing.for(
    @side,
    day: a_plaintiff_day(ordinal),
    since: since && a_plaintiff_day(since)
  )
end

def titles_of(entries) = entries.map(&:title).sort

def expected_titles(table) = table.raw.flatten.sort

# A slot on a Terms Board track, as a table reads it. Empty is nobody having
# taken a position at all; `named` is a Term on the table without a figure,
# which is a position rather than an absence.
def a_position(position)
  return "" if position.nil?

  position.money? ? (position.amount_cents / 100).to_s : "named"
end

Then("Dana's Morning Briefing on Day {int} starts her with") do |ordinal, table|
  expect(titles_of(a_briefing(ordinal).what_you_start_with)).to eq(expected_titles(table))
end

Then("Dana's Morning Briefing on Day {int} reports nothing landed and nothing served") do |ordinal|
  briefing = a_briefing(ordinal)

  expect(briefing.landed).to be_empty
  expect(briefing.served).to be_empty
end

Then("Dana's Morning Briefing on Day {int} reports landed") do |ordinal, table|
  expect(titles_of(a_briefing(ordinal).landed)).to eq(expected_titles(table))
end

Then("Dana's Morning Briefing on Day {int} reports served") do |ordinal, table|
  expect(titles_of(a_briefing(ordinal).served)).to eq(expected_titles(table))
end

# Capybara's `all` is in this World, so the matcher of the same name is not
# reached for here.
Then("Dana's Morning Briefing on Day {int} hands her nothing she could play back") do |ordinal|
  served = a_briefing(ordinal).served

  expect(served).not_to be_empty
  expect(served.map(&:playable).uniq).to eq([false])
end

Then("Dana's Morning Briefing on Day {int} reports nothing landed") do |ordinal|
  expect(a_briefing(ordinal).landed).to be_empty
end

Then("Dana's Morning Briefing on Day {int} names the Day's grammar") do |ordinal|
  expect(a_briefing(ordinal).grammar_line).to include("case file", "any order", "countersignature")
end

Then("Dana's Morning Briefing on Day {int} carries the published Rubric") do |ordinal, table|
  expect(a_briefing(ordinal).rubric.dimensions).to eq(table.raw.flatten)
end

Then("Dana's Morning Briefing on Day {int} carries what her Client wants") do |ordinal, statement|
  expect(a_briefing(ordinal).opening_statement).to include(statement)
end

Then("Dana's Morning Briefing on Day {int} carries all {int} Days") do |ordinal, count|
  expect(a_briefing(ordinal).calendar.map(&:ordinal)).to eq((1..count).to_a)
end

# The same object over a wider range of the same rows. Which Days a teammate
# missed is the caller's to say — there is no per-student state to derive it
# from, and none is added.
Then("Priya's Morning Briefing on Day {int} since Day {int} reports landed") do |ordinal, since, table|
  expect(titles_of(a_briefing(ordinal, since: since).landed)).to eq(expected_titles(table))
end

Then("Priya's Morning Briefing on Day {int} since Day {int} covers {int} Days") do |ordinal, since, count|
  expect(a_briefing(ordinal, since: since).days.count).to eq(count)
end

Then("the plaintiff Docket says what a Docket would hold") do
  expect(@side.docket).to be_empty
  expect(@side.docket.empty_state).to include("Every Action your Team spends on lands here")
end

Then("the plaintiff Docket has stopped explaining itself") do
  expect(@side.docket.empty_state).to be_nil
end

Then("the plaintiff Action Board on Day {int} prices every Action") do |ordinal, table|
  board = ActionBoard.for(@side, day: a_plaintiff_day(ordinal))
  # `landing_day` is nil where the result would land past the last Day, which is
  # a refusal rather than a Day, and an empty cell is how the table says so.
  read = board.entries.map do |entry|
    [entry.kind, entry.cost.to_s, entry.lead_time_days.to_s, entry.landing_day&.ordinal.to_s]
  end

  expect(read).to eq(table.raw)
end

Then("the plaintiff Exhibit affordances are unavailable") do
  expect(@side.case_file).not_to be_exhibits_available
end

Then("the plaintiff Exhibit affordances have appeared") do
  expect(@side.case_file).to be_exhibits_available
end

Then("the plaintiff Terms Board on Day {int} reads") do |ordinal, table|
  board = TermsBoard.for(@side, day: a_plaintiff_day(ordinal))
  read = board.tracks.map do |track|
    [track.term, a_position(track.ours), a_position(track.theirs), a_position(track.aspiration)]
  end

  expect(read).to eq(table.raw)
end

Then("no read anywhere on Day {int} shows Dana a Par") do |ordinal|
  surfaces = [
    a_briefing(ordinal),
    @side.docket,
    @side.case_file,
    ActionBoard.for(@side, day: a_plaintiff_day(ordinal)),
    TermsBoard.for(@side, day: a_plaintiff_day(ordinal))
  ]

  expect(surfaces.flat_map { |read| read.public_methods(false) }.grep(/par|score|grade/))
    .to be_empty
end
