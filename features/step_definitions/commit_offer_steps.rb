# frozen_string_literal: true

# A second member of the defendant Team. There is no roster yet, so Kofi joins
# it by acting for it.
def kofi
  @kofi ||= User.create!(
    organization: @section.organization, name: "Kofi", email: "kofi@wiu.edu"
  )
end

def a_committed_offer(ordinal)
  @side.committed_offer_on(a_plaintiff_day(ordinal))
end

def a_commit_quote(ordinal, by:, seconded_by:)
  Days::Command.quote(
    act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
    by: by, seconded_by: seconded_by
  )
end

Given("Kofi spends a {word} on Day {int} for the defendant Side") do |kind, ordinal|
  Days::Command.apply(
    act: :spend, side: @opponent, day: a_plaintiff_day(ordinal), by: kofi, kind: kind
  )
end

# The teammate who seconds is the teammate who presses the commit control, so
# the spend is attributed to them and the Offer records them as its Second.
When("Priya seconds the plaintiff Offer on Day {int}") do |ordinal|
  Days::Command.apply(
    act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
    by: priya, seconded_by: priya
  )
end

When("Dana commits the plaintiff Offer on Day {int} under the waiver") do |ordinal|
  Days::Command.apply(
    act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
    by: @student, seconded_by: nil
  )
end

When("Ravi accepts the plaintiff Offer on Day {int}, seconded by Kofi") do |ordinal|
  Offers::Accept.call(
    offer: a_committed_offer(ordinal), side: @opponent, day: a_plaintiff_day(ordinal),
    by: @teammate, seconded_by: kofi
  )
end

Then("the committed plaintiff Offer on Day {int} reads") do |ordinal, table|
  read = a_committed_offer(ordinal).offer_terms.sort_by(&:key).map do |row|
    {
      "term" => row.key,
      "amount" => row.amount_cents.nil? ? "" : (row.amount_cents / CENTS_PER_UNIT).to_s
    }
  end

  expect(read).to eq(table.hashes.map { |row| row.transform_values(&:to_s) })
end

# The Instructor never Seconds on a Team's behalf, so an Offer that landed under
# a waiver carries no seconder at all.
Then("the committed plaintiff Offer on Day {int} names nobody as its Second") do |ordinal|
  offer = a_committed_offer(ordinal)

  expect(offer).not_to be_seconded
  expect(offer.staged_by).to eq(@student)
end

Then("the plaintiff Side has committed Day {int}") do |ordinal|
  expect(DayCommitment.exists?(side: @side, day: a_plaintiff_day(ordinal))).to be(true)
end

# The control is present and dead, which is what teaches the rule.
Then("committing the plaintiff Offer on Day {int} is refused for want of a Second") do |ordinal|
  quote = a_commit_quote(ordinal, by: @student, seconded_by: nil)

  expect(quote).to be_refused
  expect(quote.refusal).to eq(:the_offer_has_not_been_seconded)
end

Then("committing the plaintiff Offer on Day {int} again is refused") do |ordinal|
  quote = a_commit_quote(ordinal, by: priya, seconded_by: priya)

  expect(quote.refusal).to eq(:an_offer_has_already_been_committed_today)
  expect {
    Days::Command.apply(
      act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
      by: priya, seconded_by: priya
    )
  }.to raise_error(Days::Command::Refused)
end

Then("the plaintiff Offer on Day {int} has been accepted by {word}") do |ordinal, name|
  acceptance = a_committed_offer(ordinal).acceptance

  expect(acceptance.accepted_by.name).to eq(name)
  expect(acceptance.side).to eq(@opponent)
  expect(acceptance.seconded_by).to eq(kofi)
end

Then("the defendant Side has spent nothing on the exchange half on Day {int}") do |ordinal|
  budget = @opponent.budget_on(a_plaintiff_day(ordinal))

  expect(budget.remaining_in(DayBudget::EXCHANGE)).to eq(budget.exchange_budget)
end
