# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offers::WaiveSecond do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:dana) { a_user(organization: organization, name: "Dana", email: "dana@wiu.edu") }
  let(:instructor) do
    a_user(organization: organization, name: "Professor Adeyemi", email: "adeyemi@wiu.edu")
  end

  def waive(on: day) = described_class.call(side: side, day: on, by: instructor)

  it "releases the gate for one Team on one Day" do
    waive

    expect(side.second_waived_on?(day)).to be(true)
  end

  it "does not persist into the next Day" do
    waive

    expect(side.second_waived_on?(simulation.days.second)).to be(false)
  end

  it "leaves the other Team's gate where it was" do
    waive

    expect(simulation.defendant_side.second_waived_on?(day)).to be(false)
  end

  it "lets a Team whose other members are absent commit what it staged" do
    offer = Offers::Stage.call(
      side: side, day: day, by: dana, terms: {"money" => 45_000_00}
    )
    waive

    expect(offer.eligible_seconders).to be_empty
    expect(offer.reload).to be_secondable
  end

  # Attribution would otherwise name someone who did not take the position.
  # The proof is structural rather than a query over an empty table: what the
  # waiver writes has nowhere to put a seconder, so no commit path built later
  # can read one out of it. It also leaves the Instructor outside the Team,
  # which is what keeps them off `eligible_seconders`.
  it "writes a row with nowhere for a seconder to go" do
    waiver = waive

    expect(waiver.granted_by).to eq(instructor)
    expect(SecondWaiver.column_names.grep(/second/)).to be_empty
    expect(side.members).not_to include(instructor)
  end

  it "is harmless to grant twice, keeping whoever granted it first" do
    first = waive
    again = described_class.call(side: side, day: day, by: dana)

    expect(again.id).to eq(first.id)
    expect(again.granted_by).to eq(instructor)
  end

  it "refuses a Day that has already closed" do
    Days::Close.call(day)

    expect { waive }.to raise_error(Offers::DayClosed)
  end

  # The race the trigger exists for, and the one the demo actually produces: the
  # Instructor grants from their own tab while a Team's commit or a deadline ends
  # the Day underneath the read. A caller is owed this seam's own refusal rather
  # than a database fault, the way `Offers::Stage` turns the same class of race
  # back into one.
  it "reads a Day that closes inside its own window as the same refusal" do
    Days::Close.call(day)
    allow(day).to receive(:closed?).and_return(false)

    expect { waive }.to raise_error(Offers::DayClosed)
  end

  # A Day the calendar holds but nobody has reached. `Day#open?` is only
  # `closed_at IS NULL`, so an unplayed Day reads as open to both this seam and
  # the trigger — and a waiver is irreversible, so one granted there silently
  # disarms the Second on a Day nobody has played yet and nothing ever says so.
  #
  # The seam owns it rather than a caller. That is the whole reason #374's same
  # finding was declined for `quoted_day`: `Days::Command` already refuses an
  # unbudgeted Day, so binding the controller would have put a second authority
  # beside the seam that owns the question. Here there was no such refusal, so
  # the answer is to give the seam one rather than to reverse that decision.
  it "refuses a Day that has not opened yet" do
    expect { waive(on: simulation.days.find_by!(ordinal: 7)) }
      .to raise_error(Offers::DayNotOpen)
  end

  # The service refuses it against a Day it holds in memory; the trigger is the
  # rule where a stale object cannot get past it.
  it "refuses one underneath the model too" do
    Days::Close.call(day)

    expect {
      SecondWaiver.create!(side: side, day: day, granted_by: instructor)
    }.to raise_error(ActiveRecord::StatementInvalid, /second_waivers_need_an_unclosed_day/)
  end
end
