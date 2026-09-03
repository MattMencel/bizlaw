# frozen_string_literal: true

Given("Dana is on the plaintiff Side") do
  @side = @simulation.plaintiff_side
  @student = User.create!(
    organization: @section.organization, name: "Dana", email: "dana@wiu.edu"
  )
end

When("Dana spends a {word} on Day {int}") do |kind, ordinal|
  Days::Command.apply(
    act: :spend,
    side: @side,
    day: @simulation.days.find_by!(ordinal: ordinal),
    by: @student,
    kind: kind
  )
end

Then("the plaintiff Side has {int} preparation points left on Day {int}") do |left, ordinal|
  budget = @side.budget_on(@simulation.days.find_by!(ordinal: ordinal))

  expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(left)
end

Then("the plaintiff Docket reads") do |table|
  read = @side.docket_entries.map do |entry|
    {
      "action" => entry.kind,
      "cost" => entry.cost.to_s,
      "spent by" => entry.spent_by.name,
      "lands on" => entry.lands_on_day.ordinal.to_s
    }
  end

  expect(read).to eq(table.hashes)
end

Then("the plaintiff Docket holds {int} entries") do |count|
  expect(@side.docket_entries.count).to eq(count)
end

Then("a {word} on Day {int} is refused because {word}") do |kind, ordinal, reason|
  quote = Days::Command.quote(
    act: :spend,
    side: @side,
    day: @simulation.days.find_by!(ordinal: ordinal),
    by: @student,
    kind: kind
  )

  expect(quote).to be_refused
  expect(quote.refusal).to eq(reason.to_sym)
end
