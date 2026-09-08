# frozen_string_literal: true

require "rails_helper"

# Who a Client is, drawn from the Case's opaque seed. Every group here is
# identity: it is settled once and never moves again, whatever the band and
# whatever the occasion.
RSpec.describe Portraits::Identity do
  let(:part_set) { Portraits::PartSet.default }

  it "draws one part from every identity group the set declares" do
    identity = described_class.for("greaves-plaintiff")

    expect(identity.parts.keys).to match_array(part_set.identity_groups.keys)
    identity.parts.each { |group, name| expect(part_set.parts(group)).to include(name) }
  end

  it "draws the same face for the same seed, every time" do
    expect(described_class.for("greaves-plaintiff")).to eq(described_class.for("greaves-plaintiff"))
  end

  # A Client's face must not move under them. If this ever fails, the hash
  # changed — and a Client whose hair changed between two Days of one Simulation
  # is a different person by the only axis two inks left available.
  it "is pinned to a hash, so an engine upgrade never reseats a face" do
    expect(described_class.for("greaves-plaintiff").parts).to eq(
      "skull" => "oval", "hair" => "straight", "garment" => "collar_sweater",
      "glasses" => "none", "facial_hair" => "none"
    )
  end

  it "reaches every part of every group over a roster" do
    roster = (1..200).map { |n| described_class.for("roster-#{n}") }

    part_set.identity_groups.each_key do |group|
      expect(roster.map { |identity| identity.part(group) }.uniq)
        .to match_array(part_set.parts(group).uniq)
    end
  end

  # ADR 0008's finding, and the one that looks correct and is not. Every group
  # reaching every part is *not* the property that matters — a correlated draw
  # passes that and still composes a fraction of the faces the set can make.
  # What has to hold is that knowing one group tells you nothing about another,
  # and the way to see it is joint coverage: every pair of groups must reach
  # every pair of their parts.
  #
  # This is the spec that catches the two implementations the prototype and its
  # first repair both got wrong — one FNV word sliced with shifts, and a
  # per-group *salted* FNV, whose low bits barely avalanche and which reaches
  # only 8 of the 32 hair-and-garment pairs the shipped set can make.
  it "draws each group independently of every other" do
    roster = (1..600).map { |n| described_class.for("roster-#{n}") }

    part_set.identity_groups.keys.combination(2) do |left, right|
      pairs = roster.map { |identity| [identity.part(left), identity.part(right)] }.uniq

      expect(pairs.size)
        .to eq(part_set.parts(left).uniq.size * part_set.parts(right).uniq.size),
          "#{left} and #{right} reached #{pairs.size} of their pairs; they move together"
    end
  end

  # Adding a group to a set is a reskin decision and must not silently reseat
  # the groups a Case's author had already looked at, so the salt is the group's
  # own name rather than its position.
  it "salts on the group's name, so the draws do not depend on each other" do
    expect(described_class.draw("hair", "greaves-plaintiff"))
      .not_to eq(described_class.draw("garment", "greaves-plaintiff"))
  end

  it "names the face in words, so a refusal can say what collided" do
    expect(described_class.for("greaves-plaintiff").to_s)
      .to include("hair straight", "garment collar_sweater")
  end
end
