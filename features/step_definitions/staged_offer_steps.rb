# frozen_string_literal: true

# Money is authored and staged in whole money and held in cents, so the table a
# scenario reads writes the amount an author would write.
CENTS_PER_UNIT = 100

def a_plaintiff_day(ordinal) = @simulation.days.find_by!(ordinal: ordinal)

# A Term's key mapped to money's amount in cents, and every other Term to nil.
def offered_terms(table)
  table.hashes.to_h do |row|
    [row.fetch("term"), row["amount"].presence&.to_i&.*(CENTS_PER_UNIT)]
  end
end

def an_instructor
  @instructor ||= User.create!(
    organization: @section.organization,
    name: "Professor Adeyemi",
    email: "adeyemi@wiu.edu"
  )
end

# There is no roster yet, so a Team's members are folded from Attribution:
# Priya joins the Team by acting for it.
def priya
  @teammate ||= User.create!(
    organization: @section.organization, name: "Priya", email: "priya@wiu.edu"
  )
end

Given("Priya spends a {word} on Day {int} for the plaintiff Side") do |kind, ordinal|
  Days::Command.apply(
    act: :spend, side: @side, day: a_plaintiff_day(ordinal), by: priya, kind: kind
  )
end

When("Priya revises the Offer on Day {int} to") do |ordinal, table|
  Offers::Stage.call(
    side: @side, day: a_plaintiff_day(ordinal), by: priya, terms: offered_terms(table)
  )
end

# Staging and revising are the same act — a revision replaces the position
# rather than amending it — so the two phrasings run the same seam.
def dana_stages(ordinal, table)
  Offers::Stage.call(
    side: @side, day: a_plaintiff_day(ordinal), by: @student, terms: offered_terms(table)
  )
end

When("Dana stages an Offer on Day {int} of") do |ordinal, table|
  dana_stages(ordinal, table)
end

When("Dana revises the Offer on Day {int} to") do |ordinal, table|
  dana_stages(ordinal, table)
end

When("Dana discards the Offer on Day {int}") do |ordinal|
  Offers::Discard.call(side: @side, day: a_plaintiff_day(ordinal))
end

When("the Instructor waives the plaintiff Second on Day {int}") do |ordinal|
  Offers::WaiveSecond.call(side: @side, day: a_plaintiff_day(ordinal), by: an_instructor)
end

Then("the plaintiff Offer on Day {int} reads") do |ordinal, table|
  offer = @side.staged_offer_on(a_plaintiff_day(ordinal))
  read = offer.offer_terms.sort_by(&:key).map do |row|
    {
      "term" => row.key,
      "amount" => row.amount_cents.nil? ? "" : (row.amount_cents / CENTS_PER_UNIT).to_s
    }
  end

  expect(read).to eq(table.hashes.map { |row| row.transform_values(&:to_s) })
end

Then("the plaintiff Side has {int} preparation points and {int} exchange points left on Day {int}") do
  |preparation, exchange, ordinal|
  budget = @side.budget_on(a_plaintiff_day(ordinal))

  expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(preparation)
  expect(budget.remaining_in(DayBudget::EXCHANGE)).to eq(exchange)
end

Then("the plaintiff Docket holds no spends") do
  expect(@side.docket.select(&:spend?)).to be_empty
end

Then("the plaintiff Docket reads as acts") do |table|
  read = @side.docket.map do |entry|
    {"act" => entry.act.to_s, "by" => entry.by.name, "cost" => entry.cost.to_s}
  end

  expect(read).to eq(table.hashes.map { |row| row.transform_values(&:to_s) })
end

Then("the Offer on Day {int} can be seconded by {word}") do |ordinal, name|
  offer = @side.staged_offer_on(a_plaintiff_day(ordinal))

  expect(offer.eligible_seconders.map(&:name)).to eq([name])
end

Then("the Offer on Day {int} cannot be seconded at all") do |ordinal|
  offer = @side.staged_offer_on(a_plaintiff_day(ordinal))

  # The control is present and dead. That is what teaches the rule.
  expect(offer.eligible_seconders).to be_empty
  expect(offer).not_to be_secondable
end

Then("the Offer on Day {int} can be committed") do |ordinal|
  expect(@side.staged_offer_on(a_plaintiff_day(ordinal))).to be_secondable
end

Then("the plaintiff Second is not waived on Day {int}") do |ordinal|
  expect(@side.second_waived_on?(a_plaintiff_day(ordinal))).to be(false)
end

Then("the defendant Second is not waived on Day {int}") do |ordinal|
  expect(@simulation.defendant_side.second_waived_on?(a_plaintiff_day(ordinal))).to be(false)
end

# The Instructor never Seconds on a Team's behalf: Attribution would then name
# someone who did not take the position.
Then("no Offer names Professor Adeyemi as its seconder") do
  expect(CommittedOffer.where(seconded_by_user_id: an_instructor.id)).to be_empty
end

Then("the plaintiff Side has no Offer on Day {int}") do |ordinal|
  expect(@side.staged_offer_on(a_plaintiff_day(ordinal))).to be_nil
  expect(StagedOfferTerm.count).to eq(0)
end
