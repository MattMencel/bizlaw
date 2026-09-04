# frozen_string_literal: true

Given("Ravi is on the defendant Side") do
  @opponent = @simulation.defendant_side
  @teammate = User.create!(
    organization: @section.organization, name: "Ravi", email: "ravi@wiu.edu"
  )
end

Given("Day {int} runs to {string}") do |ordinal, deadline|
  a_day(ordinal).update!(deadline_at: Time.zone.parse(deadline))
end

When("Ravi spends a {word} on Day {int}") do |kind, ordinal|
  Days::Command.apply(
    act: :spend, side: @opponent, day: a_day(ordinal), by: @teammate, kind: kind
  )
end

When("Dana commits Day {int}") do |ordinal|
  Days::Commit.call(side: @side, day: a_day(ordinal), by: @student)
end

When("both Sides commit Day {int}") do |ordinal|
  day = a_day(ordinal)
  Days::Commit.call(side: @side, day: day, by: @student)
  Days::Commit.call(side: @opponent, day: day, by: @teammate)
end

When("every Day up to Day {int} is committed by both Sides") do |last|
  (1..last).each do |ordinal|
    day = a_day(ordinal)
    Days::Commit.call(side: @side, day: day, by: @student)
    Days::Commit.call(side: @opponent, day: day, by: @teammate)
  end
end

# The Instructor's force-close is the one close path itself rather than a
# wrapper over it: a second name would be a second path to keep true.
When("the Instructor force-closes Day {int}") do |ordinal|
  Days::Close.call(a_day(ordinal))
end

When("the Instructor extends Day {int} to {string}") do |ordinal, deadline|
  Days::ExtendDeadline.call(a_day(ordinal), to: Time.zone.parse(deadline))
end

When("the deadline sweep runs at {string}") do |at|
  Days::FireDeadlines.call(scope: @simulation.days, at: Time.zone.parse(at))
end

Then("Days {int} to {int} have closed") do |first, last|
  open = (first..last).map { |ordinal| a_day(ordinal) }.select(&:open?)

  expect(open.map(&:ordinal)).to be_empty
end

Then("Day {int} is open") do |ordinal|
  expect(a_day(ordinal)).to be_open
end

Then("Day {int} is open with {int} preparation points and {int} exchange points for each Side") do
  |ordinal, preparation, exchange|
  day = a_day(ordinal)
  quotas = DayBudget.where(day: day)

  expect(day).to be_open
  expect(quotas.count).to eq(2)
  expect(quotas.map { |quota| quota.remaining_in(DayBudget::PREPARATION) }.uniq).to eq([preparation])
  expect(quotas.map { |quota| quota.remaining_in(DayBudget::EXCHANGE) }.uniq).to eq([exchange])
end

Then("Day {int} has no Budget yet") do |ordinal|
  expect(DayBudget.where(day: a_day(ordinal))).to be_empty
end

Then("the Simulation has no Day {int}") do |ordinal|
  expect(@simulation.days.find_by(ordinal: ordinal)).to be_nil
end

def a_day(ordinal) = @simulation.days.find_by!(ordinal: ordinal)
