# frozen_string_literal: true

Given("the reference Case has been imported") do
  @case_version = Cases::Import.call(Rails.root.join("db/cases/reference.yml"))
end

Given("a Section at Western Illinois University") do
  organization = Organization.create!(name: "Western Illinois University")
  @section = Section.create!(organization: organization, name: "LAW 301, Fall")
end

Given("the reference Case also has a draft version") do
  # A draft carries the same authored Budget as the version it is worked from.
  @draft = @case_version.case.versions.create!(
    version: "1.1.0",
    budget_per_day: @case_version.budget_per_day,
    exchange_pool: @case_version.exchange_pool,
    exhibit_price: @case_version.exhibit_price,
    closing_knee: @case_version.closing_knee,
    closing_preparation: @case_version.closing_preparation,
    closing_exchange: @case_version.closing_exchange
  )
  @draft.calendar_days.create!(ordinal: 1, in_fiction_date: Date.new(2026, 3, 2))
end

When("the Instructor creates a Simulation of the reference Case") do
  @simulation = Simulations::Create.call(section: @section, case_version: @case_version)
end

When("the Instructor tries to create a Simulation of the draft version") do
  Simulations::Create.call(section: @section, case_version: @draft)
rescue ActiveRecord::RecordInvalid => e
  @refusal = e
end

Then("the Simulation has {int} Days") do |count|
  expect(@simulation.days.count).to eq(count)
end

Then("the Days run in order from {word} to {word}") do |first, last|
  ordinals = @simulation.days.map(&:ordinal)
  expect(ordinals).to eq((1..ordinals.length).to_a)
  expect(@simulation.days.first.in_fiction_date).to eq(Date.parse(first))
  expect(@simulation.days.last.in_fiction_date).to eq(Date.parse(last))
end

Then("every Day is open") do
  expect(@simulation.days.reject(&:open?)).to be_empty
end

Then("the Simulation has a plaintiff Side and a defendant Side") do
  expect(@simulation.sides.map(&:role)).to contain_exactly("plaintiff", "defendant")
end

Then("the Simulation is refused") do
  expect(@refusal).to be_a(ActiveRecord::RecordInvalid)
  expect(Simulation.count).to eq(0)
end
