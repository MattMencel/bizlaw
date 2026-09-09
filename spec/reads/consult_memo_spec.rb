# frozen_string_literal: true

require "rails_helper"

# What a Consult buys. Nothing is written for it beyond the spend's own Docket
# row, so every expectation here is a fold: the band from the shift ledger as of
# that row, the wording from the band the Case authored, the face from the seed.
RSpec.describe ConsultMemo do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }

  def a_consult
    Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::CONSULT_CLIENT
    )
  end

  def a_shift(fraction, at: Time.current)
    side.client_shifts.create!(
      day: day,
      source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
      source_ref: rand(1..1_000_000),
      requested_fraction: fraction,
      created_at: at
    )
  end

  it "hands back the band, the Client's words and their face" do
    beat = described_class.for(a_consult).beat

    expect(beat.client_role).to eq(Side::PLAINTIFF)
    expect(beat.band).to eq(CaseClientBand::FIRM)
    expect(beat.line).to be_present
    expect(beat.portrait_seed).to eq(side.client.portrait_seed)
  end

  # The expression *is* the band, by engine rule, so a Client's face cannot
  # change between two variants that mean the same thing.
  it "draws the face from the band rather than from the variant" do
    first = described_class.for(a_consult).beat
    second = described_class.for(a_consult).beat

    expect([first, second].map(&:expression)).to eq([CaseClientBand::FIRM] * 2)
    expect(first.line).not_to eq(second.line)
  end

  it "speaks a line the Case authored under the band it read" do
    beat = described_class.for(a_consult).beat

    expect(side.client.band_named(CaseClientBand::FIRM).lines.map(&:body)).to include(beat.line)
  end

  # A Consult can be bought again — nothing refuses it, and the price is what
  # discourages it rather than a rule. The second reads the same band and draws
  # the next variant, and comes back round once the variants run out.
  it "advances the variant on each Consult and comes back round" do
    lines = Array.new(3) { described_class.for(a_consult).beat.line }

    expect(lines.first).not_to eq(lines.second)
    expect(lines.third).to eq(lines.first)
  end

  # The whole of ADR 0006. The row is re-readable forever and reads back what
  # the Client said then; a band that moves is shown at the next Consult, not
  # the moment it moves.
  it "reads back what the Client said when it was bought" do
    before_the_blow = described_class.for(a_consult)
    a_shift(0.9)
    after_it = described_class.for(a_consult)

    expect(after_it.band).to eq(CaseClientBand::READY)
    expect(before_the_blow.beat.band).to eq(CaseClientBand::FIRM)
  end

  it "keeps saying what it said when the Team re-reads it later" do
    a_consult
    a_shift(0.9)

    expect(side.consults.sole.band).to eq(CaseClientBand::FIRM)
  end

  # The other half of ADR 0006, and what the per-node count has to leave intact:
  # the words are as frozen as the band. Every Consult after this one is written
  # with a higher id, so none of them reaches back into what this one counted.
  it "keeps saying the same words however the run goes on around it" do
    entry = a_consult
    said = described_class.for(entry).beat.line
    a_consult
    a_shift(0.9)
    a_consult

    expect(described_class.for(entry).beat.line).to eq(said)
    expect(side.consults.first.beat.line).to eq(said)
  end

  it "carries the Day it was bought on and the instant it was spoken" do
    entry = a_consult
    memo = described_class.for(entry)

    expect(memo.day).to eq(day)
    expect(memo.spoken_at).to eq(entry.created_at)
  end

  # A memo over a deposition would have no band to fold and no node to speak.
  # That is a caller with the wrong row, not a refusal a student should see.
  it "refuses a spend that bought paper rather than a Client" do
    deposition = Days::Command.apply(
      act: :spend, side: side, day: day, by: dana, kind: CaseAction::DEPOSE_WITNESS
    )

    expect { described_class.for(deposition) }.to raise_error(described_class::NotAConsult)
  end

  it "counts only this Team's own Consults toward the variant" do
    Days::Command.apply(
      act: :spend, side: simulation.defendant_side, day: day, by: dana,
      kind: CaseAction::CONSULT_CLIENT
    )

    expect(described_class.for(a_consult).beat.line)
      .to eq(side.client.band_named(CaseClientBand::FIRM).line(0, seed: simulation.seed))
  end

  # The run's own seed reaches the selection, which is what stops every Team on
  # one Case hearing its Client's lines in one fixed order.
  it "chooses the variant with the run's own seed" do
    expect(described_class.for(a_consult).beat.line)
      .to eq(side.client.band_named(CaseClientBand::FIRM).line(0, seed: simulation.seed))
  end

  # A node is the band, not the Side. A Team that consults once while firm and
  # then once the Client is ready hears the *ready* node's opening line, not its
  # second — the firm Consult spoke a different node and advanced nothing here.
  it "counts the Consults that heard this band and not the ones that heard another" do
    a_consult
    a_shift(0.9)
    ready = side.client.band_named(CaseClientBand::READY)

    expect(described_class.for(a_consult).beat.line).to eq(ready.line(0, seed: simulation.seed))
  end

  it "advances within the band a second Consult reads" do
    a_consult
    a_shift(0.9)
    heard = Array.new(2) { described_class.for(a_consult).beat.line }
    ready = side.client.band_named(CaseClientBand::READY)

    expect(heard).to eq([ready.line(0, seed: simulation.seed), ready.line(1, seed: simulation.seed)])
    expect(heard.uniq.size).to eq(2)
  end
end
