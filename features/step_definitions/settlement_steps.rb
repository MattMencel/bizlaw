# frozen_string_literal: true

# The settlement beat. Nothing is written for the instrument — it is a read over
# the accepted Offer, its Terms and the Acceptance — so every step here asks
# `ExecutedInstrument` rather than looking for a row.

def an_instrument(side) = ExecutedInstrument.for(side)

def a_term_sheet(side)
  an_instrument(side).terms.map do |term|
    {
      "term" => term.key,
      "amount" => term.amount_cents.nil? ? "" : (term.amount_cents / CENTS_PER_UNIT).to_s
    }
  end
end

When("Ravi commits Day {int}") do |ordinal|
  Days::Commit.call(side: @opponent, day: a_plaintiff_day(ordinal), by: @teammate)
end

When("Ravi takes the plaintiff Offer from Day {int} on Day {int}, seconded by Kofi") do |made, taken|
  Offers::Accept.call(
    offer: @side.committed_offer_on(a_plaintiff_day(made)),
    side: @opponent,
    day: a_plaintiff_day(taken),
    by: @teammate,
    seconded_by: kofi
  )
end

Then("the Simulation has settled") do
  expect(@simulation.reload).to be_settled
end

# The Day exists on the calendar — every Day of a Simulation is written before
# the first is played — and it was never handed a quota, which is what a Day
# opening means.
Then("Day {int} was never opened") do |ordinal|
  day = a_plaintiff_day(ordinal)

  expect(day).to be_open
  expect(day.budgets).to be_empty
end

Then("staging an Offer on Day {int} is refused, because the run has ended") do |ordinal|
  expect {
    Offers::Stage.call(
      side: @side, day: a_plaintiff_day(ordinal), by: @student, terms: {"money" => 1_000_00}
    )
  }.to raise_error(Simulation::AlreadySettled)
end

Then("committing Day {int} is refused, because the run has ended") do |ordinal|
  expect { Days::Commit.call(side: @side, day: a_plaintiff_day(ordinal), by: @student) }
    .to raise_error(Simulation::AlreadySettled)
end

Then("the executed instrument reads") do |table|
  expect(an_instrument(@side)).to be_executed
  expect(a_term_sheet(@side)).to eq(table.hashes.map { |row| row.transform_values(&:to_s) })
end

Then("it is the same term sheet for both Teams") do
  expect(a_term_sheet(@opponent)).to eq(a_term_sheet(@side))
end

# An Acceptance *is* a countersignature, so both lines are filled by the time
# there is an instrument to read at all.
Then("it carries Dana's signature and Ravi's countersignature") do
  read = an_instrument(@side)

  expect(read.offered_by.side_role).to eq(Side::PLAINTIFF)
  expect(read.offered_by.signed_by).to eq(@student)
  expect(read.accepted_by.side_role).to eq(Side::DEFENDANT)
  expect(read.accepted_by.signed_by).to eq(@teammate)
  expect(read.executed_on).to eq(an_instrument(@opponent).executed_on)
end

Then("the plaintiff Client says their line for having it taken") do
  beat = an_instrument(@side).beat

  expect(beat.client_role).to eq(Side::PLAINTIFF)
  expect(beat.acceptance_role).to eq(CaseClient::HAD_IT_TAKEN)
  expect(beat.line).to eq(@side.client.settlement_line(CaseClient::HAD_IT_TAKEN))
end

Then("the defendant Client says their line for taking it") do
  beat = an_instrument(@opponent).beat

  expect(beat.client_role).to eq(Side::DEFENDANT)
  expect(beat.acceptance_role).to eq(CaseClient::TOOK_IT)
  expect(beat.line).to eq(@opponent.client.settlement_line(CaseClient::TOOK_IT))
end

# *firm* and *ready* mean willing to keep holding out, which is moot once the
# instrument is executed. The face appears anyway, and it is invariant.
Then("neither Client shows a Reaction Band") do
  beats = [an_instrument(@side).beat, an_instrument(@opponent).beat]

  expect(beats.map(&:members).uniq)
    .to eq([%i[client_role acceptance_role line expression portrait_seed]])
  expect(beats.map(&:expression).uniq).to eq([ExecutedInstrument::EXPRESSION])
end

# The beat carries a seed and an expression rather than a rendered portrait,
# because the compositor takes the render size as an argument and a read has no
# business choosing one. The face is composed here, at the size a page serves.
#
# The two Clients of one Case are the only pair anybody ever sees together, and
# `Cases::Import` is what guarantees they are two people.
Then("each Team sees its own Client's face, and they are two different people") do
  faces = [@side, @opponent].map do |side|
    beat = an_instrument(side).beat
    Portraits::Compose.call(
      seed: beat.portrait_seed, expression: beat.expression, size: Portraits::Compose::SIZES.first
    )
  end

  expect(faces.first).not_to eq(faces.last)
  expect(faces.reject { |face| face.include?(%(aria-hidden="true")) }).to be_empty
end
