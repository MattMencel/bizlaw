# frozen_string_literal: true

require "rails_helper"

# A Team plays out of its own Case File. That is a boundary the run's usual
# tenancy key cannot express — the two Sides share a Simulation and an
# Organization, so `(parent_id, simulation_id, organization_id)` on both parents
# would cheerfully take the opponent's document. `staged_offer_exhibits` keys
# both its parents by `side_id` instead, which is narrower and gives tenancy for
# nothing: a Side belongs to exactly one Simulation in exactly one Organization.
#
# These specs write the row the boundary is supposed to refuse, at the level
# below `Offers::Stage`'s own guard, and expect the database to raise.
RSpec.describe "the Side boundary" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:dana) { a_user(organization: simulation.section.organization, name: "Dana") }

  let(:offer) do
    Offers::Stage.call(side: side, day: day, by: dana, terms: {"money" => 45_000_00})
  end

  def a_case_file_row(holder)
    CaseFileDocument.create!(
      side: holder, day: day, case_document: simulation.case_version.documents.first
    )
  end

  it "refuses an Exhibit riding an Offer out of the other Team's Case File" do
    theirs = a_case_file_row(opponent)

    expect {
      StagedOfferExhibit.create!(staged_offer: offer, case_file_document: theirs)
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "takes one out of the Team's own" do
    ours = a_case_file_row(side)

    expect {
      StagedOfferExhibit.create!(staged_offer: offer, case_file_document: ours)
    }.not_to raise_error
  end

  it "keys the row to the Side whose Offer it rides" do
    ours = a_case_file_row(side)

    riding = StagedOfferExhibit.create!(staged_offer: offer, case_file_document: ours)

    expect(riding.side_id).to eq(side.id)
  end

  # The Side defaults from the Offer and is not overwritten when a caller
  # supplies one, exactly as the tenancy columns beside it are not. The two keys
  # then meet in the middle: a caller that relabels the row is refused by the
  # Offer's key rather than quietly writing a row that reads as the opponent's.
  it "refuses a row relabelled to the other Side" do
    ours = a_case_file_row(side)

    expect {
      StagedOfferExhibit.create!(
        staged_offer: offer, case_file_document: ours, side_id: opponent.id
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
