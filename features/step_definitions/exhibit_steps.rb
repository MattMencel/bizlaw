# frozen_string_literal: true

# The Exhibits riding a draft are part of the position, so attaching one is a
# revision of the Offer rather than a second act: the Terms already on the table
# are staged again alongside the document being added.
def attach_an_exhibit(side:, role:, ordinal:, by:, title:)
  day = a_plaintiff_day(ordinal)
  offer = side.staged_offer_on(day)

  Offers::Stage.call(
    side: side, day: day, by: by,
    terms: offer.offer_terms.to_h { |row| [row.key, row.amount_cents] },
    exhibits: offer.exhibits.to_a + [a_filed_document(role, title)]
  )
end

When("Dana attaches {string} to the Offer on Day {int}") do |title, ordinal|
  attach_an_exhibit(
    side: @side, role: "plaintiff", ordinal: ordinal, by: @student, title: title
  )
end

When("Ravi stages an Offer on Day {int} of") do |ordinal, table|
  Offers::Stage.call(
    side: @opponent, day: a_plaintiff_day(ordinal), by: @teammate, terms: offered_terms(table)
  )
end

When("Ravi attaches {string} to the Offer on Day {int}") do |title, ordinal|
  attach_an_exhibit(
    side: @opponent, role: "defendant", ordinal: ordinal, by: @teammate, title: title
  )
end

When("Kofi seconds the defendant Offer on Day {int}") do |ordinal|
  Days::Command.apply(
    act: :commit_offer, side: @opponent, day: a_plaintiff_day(ordinal),
    by: kofi, seconded_by: kofi
  )
end

# Nothing but a play draws on this half, so the point that leaves the Side
# unable to afford both is written straight into the ledger.
Given("the plaintiff exchange half has one point left on Day {int}") do |ordinal|
  day = a_plaintiff_day(ordinal)
  @side.docket_entries.create!(
    day: day, lands_on_day: day, spent_by: priya,
    case_action: nil, cost: 1, half: DayBudget::EXCHANGE
  )
end

# A partial ride would silently drop an Exhibit the Team meant to play, which is
# the worst available failure on an irreversible act.
Then("committing the plaintiff Offer on Day {int} is refused for want of Budget") do |ordinal|
  quote = Days::Command.quote(
    act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
    by: @student, seconded_by: priya
  )

  expect(quote.refusal).to eq(:the_budget_cannot_cover_it)
  expect {
    Days::Command.apply(
      act: :commit_offer, side: @side, day: a_plaintiff_day(ordinal),
      by: @student, seconded_by: priya
    )
  }.to raise_error(Days::Command::Refused)
end

# Service gives a Team knowledge, never ammunition: the document arrives, and
# the Exhibit property on it does not.
Then("the {word} Case File holds {string} as served") do |role, title|
  filed = a_filed_document(role, title)

  expect(filed).to be_served
  expect(filed).not_to be_exhibit
  expect(filed.exhibit_shift_fraction).to be_nil
  expect(filed).not_to be_playable
end

Then("the {word} Case File holds {string} as found") do |role, title|
  expect(a_filed_document(role, title)).not_to be_served
end

# The Exhibit is spent when played; the document is not, and stays in the
# playing Team's own Case File as what it knows.
Then("the {word} has spent {string}") do |role, title|
  filed = a_filed_document(role, title)

  expect(filed).to be_played
  expect(filed).not_to be_playable
end

Then("the defendant Side has {int} preparation points and {int} exchange points left on Day {int}") do
  |preparation, exchange, ordinal|
  budget = @opponent.budget_on(a_plaintiff_day(ordinal))

  expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(preparation)
  expect(budget.remaining_in(DayBudget::EXCHANGE)).to eq(exchange)
end
