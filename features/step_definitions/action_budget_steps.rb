# frozen_string_literal: true

When("Day {int} opens") do |ordinal|
  Days::Open.call(@simulation.days.find_by!(ordinal: ordinal))
end

When("the Section doubles its Action Budget") do
  @section.update!(budget_per_day: @case_version.budget_per_day * 2)
end

Then("each Side has {int} preparation points and {int} exchange points on Day {int}") do
  |preparation, exchange, ordinal|
  quotas = DayBudget.where(day: @simulation.days.find_by!(ordinal: ordinal))

  expect(quotas.count).to eq(2)
  expect(quotas.map(&:preparation_budget).uniq).to eq([preparation])
  expect(quotas.map(&:exchange_budget).uniq).to eq([exchange])
end
