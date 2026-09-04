# frozen_string_literal: true

require "rails_helper"

# ADR 0002 puts the Second in the database: `CHECK (seconded_by_user_id !=
# staged_by_user_id)`. It is the one invariant the committed table carries now,
# and it is written at the level below the models so that an insert path added
# later cannot get round it.
#
# The waiver is the reason the CHECK is written plainly rather than guarded for
# null. In SQL a CHECK fails only on false, and `NULL != x` is neither true nor
# false, so an Offer that landed under an Instructor's waiver — carrying no
# seconder at all — passes the same constraint that refuses a Team member
# confirming their own position.
RSpec.describe "the Second" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:ravi) { a_user(organization: organization, name: "Ravi", email: "ravi@wiu.edu") }

  def commit(staged_by:, seconded_by:)
    CommittedOffer.create!(
      side: side, day: day, staged_by: staged_by, seconded_by: seconded_by
    )
  end

  it "refuses an Offer a member seconded for themselves" do
    expect { commit(staged_by: dana, seconded_by: dana) }
      .to raise_error(ActiveRecord::StatementInvalid, /committed_offers_second_is_another_member/)
  end

  it "admits an Offer a teammate seconded" do
    expect(commit(staged_by: dana, seconded_by: ravi)).to be_seconded
  end

  it "admits an Offer that landed under a waiver, carrying no seconder" do
    expect(commit(staged_by: dana, seconded_by: nil)).not_to be_seconded
  end

  # The committed table is where every cross-Side read goes precisely because it
  # holds no live positions. This ticket creates it and leaves it empty.
  it "starts empty" do
    expect(CommittedOffer.count).to eq(0)
  end
end
