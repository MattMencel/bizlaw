# frozen_string_literal: true

require "rails_helper"

# The Instructor's one act inside a running Day, and the seam between their
# address and `Offers::WaiveSecond`. What is under test is who it is attributed
# to, what it changes on the Team's own page, and what it cannot be made to do.
RSpec.describe "waiving the Second", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }

  def waive(role: Side::PLAINTIFF, on: Demo::Seed::DEMO_DAY, run: Demo::Seed::DEMO)
    post "/demo/#{run}/#{Demo::Seat::INSTRUCTOR}/waivers", params: {role: role, day: on}
  end

  it "grants it and sends them back to the minute" do
    expect { waive }.to change { side.second_waivers.count }.by(1)

    expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}")
  end

  # The waiver is granted rather than exercised, so what the row names is who
  # granted it — and the Instructor is on no Side, so this cannot make them a
  # member of one. `second_waivers` sits outside the `Side#members` fold for
  # exactly this, and the map's standing constraint is that the plaintiff stays
  # a Side of one however many acts land on it.
  it "attributes it to the Instructor without seating them on the Side" do
    waive

    expect(side.second_waivers.sole.granted_by).to eq(instructor)
    expect(side.members.map(&:email)).to eq([Demo::Seed::PLAYER_EMAIL])
  end

  # The whole point of the act, read from the Team's own page: the gate the
  # countersignature block could not clear is clear, with nobody named as having
  # signed anything.
  it "brings the Team's execute control alive" do
    Offers::Stage.call(side: side, day: day, by: side.members.sole, terms: {"apology" => nil})

    get "/demo/#{Demo::Seed::DEMO}"
    expect(inertia.props[:countersignature][:execution][:refusal])
      .to eq(I18n.t("reads.refusals.the_offer_has_not_been_seconded"))

    waive

    get "/demo/#{Demo::Seed::DEMO}"
    expect(inertia.props[:countersignature][:execution][:refusal]).to be_nil
  end

  # `CONTEXT.md` § Second: a waiver is on the record as an Instructor action
  # rather than as a silent change in what a control will do.
  it "puts it on the Team's Docket as an Instructor action" do
    waive

    get "/demo/#{Demo::Seed::DEMO}"
    line = inertia.props[:back][:docket][:entries].find { |e| e[:act] == "second_waived" }

    expect(line).to include(by: instructor.name, instructor_action: true, cost: nil)
  end

  # Granted to one Team for one Day, and the ledger is the authority on both.
  it "leaves the other Side and the next Day ungranted" do
    waive

    expect(simulation.defendant_side.second_waived_on?(day)).to be(false)
    expect(side.second_waived_on?(simulation.days.find_by!(ordinal: 4))).to be(false)
  end

  # Two presses are the ordinary case on a page that re-reads itself, and the
  # unique index underneath keeps the row of whoever granted it first.
  it "is harmless to grant twice" do
    waive
    expect { waive }.not_to change { side.second_waivers.count }
  end

  describe "what it refuses" do
    # The Day ended under the minute. It is already a refusal the engine names,
    # so it comes back as the engine's own sentence rather than as a fault —
    # and it writes nothing, which is why the line is still there to carry it.
    it "refuses a Day that has closed, and says so on the line" do
      Days::Commit.call(side: side, day: day, by: side.members.sole)

      expect { waive }.not_to change { side.second_waivers.count }

      follow_redirect!
      line = inertia.props[:lines].find { |l| l[:role] == Side::PLAINTIFF }
      expect(line[:refusal]).to eq(I18n.t("reads.refusals.the_day_has_closed"))
    end

    # Read exactly once: the shelf is cleared on the way past, so a reload does
    # not restate a refusal that has already been read.
    it "does not restate the refusal on the next read" do
      Days::Commit.call(side: side, day: day, by: side.members.sole)
      waive
      follow_redirect!

      get "/demo/#{Demo::Seed::DEMO}/#{Demo::Seat::INSTRUCTOR}"

      expect(inertia.props[:lines].pluck(:refusal)).to eq([nil, nil])
    end

    it "does not know a Side the run does not have" do
      waive(role: "arbitrator")

      expect(response).to have_http_status(:not_found)
    end

    it "does not know a Day off the calendar" do
      waive(on: 99)

      expect(response).to have_http_status(:not_found)
    end

    # A Day the calendar holds but nobody has reached. The minute renders the
    # sitting Day and posts that, so this cannot come from the page — and a
    # waiver cannot be taken back, so one granted into the future would disarm
    # the Second on a Day nobody had played with nothing anywhere saying so.
    it "does not grant one on a Day nobody has reached" do
      expect { waive(on: 7) }.not_to change { SecondWaiver.count }

      expect(response).to have_http_status(:not_found)
    end

    it "does not know a run it did not lay down" do
      waive(run: "whatever")

      expect(response).to have_http_status(:not_found)
    end
  end
end
