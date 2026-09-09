# frozen_string_literal: true

# A Consult writes one `docket_entries` row and nothing else. The band is folded
# from the shift ledger as of that row and the wording is authored under the
# band, so every step here asks a read rather than looking for a row.

def a_consult(ordinal)
  Days::Command.apply(
    act: :spend, side: @side, day: a_plaintiff_day(ordinal),
    by: @student, kind: CaseAction::CONSULT_CLIENT
  )
end

When("Dana consults her Client on Day {int}") do |ordinal|
  @consults ||= []
  @consults << ConsultMemo.for(a_consult(ordinal))
end

# The reference Case's Exhibits cannot carry one Client four fifths of the way
# on their own — one document moves one Client once — so the blow is written
# straight into the ledger, the way the exchange half is drained in
# `exhibit_steps.rb`. What is under test is the fold, not how the shift arrived.
When("the plaintiff Client is moved most of the way through their bound") do
  @side.client_shifts.create!(
    day: a_plaintiff_day(1),
    source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
    source_ref: 1,
    requested_fraction: 0.9
  )
end

Then("her Client is {word}") do |band|
  expect(@consults.last.band).to eq(band)
end

Then("the Consult Dana already bought still reads {word}") do |band|
  expect(@side.consults.first.band).to eq(band)
  expect(@consults.first.beat.band).to eq(band)
end

# The Client's beat is emphasis and never the sole carrier. A Consult yields no
# document, so the Docket line is the only other carrier there is.
Then("the Consult is on the plaintiff Docket, and the line says {word}") do |band|
  line = @side.docket.entries.sole

  expect(line.kind).to eq(CaseAction::CONSULT_CLIENT)
  expect(line.band).to eq(band)
end

# The expression is the band by engine rule, so a Client's face cannot change
# between two variants that mean the same thing. The beat hands on a seed and an
# expression; the size is the serving page's to choose.
Then("her Client's face is drawn from the band") do
  beat = @consults.last.beat

  expect(beat.expression).to eq(beat.band)
  expect(
    Portraits::Compose.call(
      seed: beat.portrait_seed, expression: beat.expression,
      size: Portraits::Compose::SIZES.first
    )
  ).to include("<svg")
end

# A Consult can be bought again, and the second draws the next variant: one line
# per band would come back word for word.
Then("the two Consults are answered in different words") do
  expect(@consults.map { |memo| memo.beat.line }.uniq.size).to eq(@consults.size)
end

# The node a variant is selected on is the band, not the Side: the firm Consult
# spoke a different node, so the ready Client opens on its own first variant
# rather than skipping it. Which variant that is belongs to the run's seed,
# which is why this asks the band rather than naming a line.
Then("the ready Client answered with its own two variants, in order") do
  ready = @side.client.band_named(CaseClientBand::READY)
  seed = @side.simulation.seed
  answered = @consults.select { |memo| memo.band == CaseClientBand::READY }

  expect(answered.map { |memo| memo.beat.line })
    .to eq([ready.line(0, seed: seed), ready.line(1, seed: seed)])
end
