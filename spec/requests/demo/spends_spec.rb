# frozen_string_literal: true

require "rails_helper"

# The first write in the app. What is under test is the seam between the address
# and `Days::Command`: which Side is charged, who the act is attributed to, and
# what comes back when the Day will not have it.
RSpec.describe "spending an Action", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY) }

  def spend(kind, run: Demo::Seed::DEMO, seat: nil)
    post ["/demo/#{run}", seat, "spends"].compact.join("/"), params: {kind: kind}
  end

  describe "an Action the half will cover" do
    it "charges it and sends him back to the draft" do
      expect { spend(CaseAction::CONSULT_CLIENT) }
        .to change { side.docket_entries.count }.by(1)

      expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}")
    end

    # The map's standing constraint: `Side#members` folds from Attribution, so
    # an act attributed to anyone else would put a second member on this Side
    # and make the countersignature block live.
    it "attributes it to the seat that took it" do
      spend(CaseAction::CONSULT_CLIENT)

      expect(side.docket_entries.where(day: day).sole.spent_by.email)
        .to eq(Demo::Seed::PLAYER_EMAIL)
      expect(side.members.map(&:email)).to eq([Demo::Seed::PLAYER_EMAIL])
    end

    it "takes it out of the half the Case authored it against" do
      expect { spend(CaseAction::RETAIN_EXPERT) }
        .to change { side.budget_on(day).remaining_in(DayBudget::PREPARATION) }.from(8).to(3)
    end

    # A lead time of zero lands on the Day it was bought, and the draft is
    # re-read from scratch — so the front matter carries it before he has
    # turned any page.
    it "puts a landing on the page he is sent back to" do
      spend(CaseAction::CONSULT_CLIENT)
      follow_redirect!

      expect(inertia.props[:back][:docket][:entries].pluck(:kind))
        .to include(CaseAction::CONSULT_CLIENT)
    end
  end

  # The second tab is a different person on the other Side, and the address is
  # the whole of what says so.
  it "charges the Side the seat sits on" do
    before_count = side.docket_entries.count

    expect { spend(CaseAction::CONSULT_CLIENT, seat: Side::DEFENDANT) }
      .to change { simulation.defendant_side.docket_entries.count }.by(1)

    expect(side.docket_entries.count).to eq(before_count)
    expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}/#{Side::DEFENDANT}")
  end

  # One seat, one address, however it was reached — which is what the slip posts
  # to as well. #360 handed the player the bare form, and the first act he takes
  # should not spell his seat out from under him.
  it "keeps the player on the address he was handed" do
    spend(CaseAction::CONSULT_CLIENT, seat: Side::PLAINTIFF)

    expect(response).to redirect_to("/demo/#{Demo::Seed::DEMO}")
  end

  describe "an Action the half will not cover" do
    # 8 points of preparation, and nothing left after these two.
    before do
      [CaseAction::RETAIN_EXPERT, CaseAction::DEPOSE_WITNESS].each do |kind|
        Days::Command.apply(act: :spend, side: side, day: day, by: side.members.sole, kind: kind)
      end
    end

    it "refuses it without charging, and says so on the line that refused" do
      expect { spend(CaseAction::CONSULT_CLIENT) }.not_to change { side.docket_entries.count }

      follow_redirect!
      line = inertia.props[:slip][:actions].find { |a| a[:kind] == CaseAction::CONSULT_CLIENT }
      expect(line).to include(refused_just_now: true)
      expect(line[:refusal]).to eq("Today's half will not cover it.")
    end

    # The refusal has no row anywhere. It survives exactly one read.
    it "does not carry the refusal into the next read of the same page" do
      spend(CaseAction::CONSULT_CLIENT)
      follow_redirect!

      get "/demo/#{Demo::Seed::DEMO}"

      expect(inertia.props[:slip][:actions]).to all(include(refused_just_now: false))
    end

    it "leaves the other five refused too, and unmarked" do
      spend(CaseAction::CONSULT_CLIENT)
      follow_redirect!

      others = inertia.props[:slip][:actions]
        .reject { |a| a[:kind] == CaseAction::CONSULT_CLIENT }
      expect(others).to all(include(affordable: false, refused_just_now: false))
      expect(others.pluck(:refusal)).to all(be_present)
    end
  end

  # A kind off no menu the engine ever offered. Nothing on the page can produce
  # it, so it is the reader's doing and reads as one — the same answer a
  # mistyped seat gets.
  it "does not know an Action the Case never authored" do
    expect { spend("subpoena_the_mayor") }.not_to change(DocketEntry, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "has nothing for the Instructor to spend" do
    spend(CaseAction::CONSULT_CLIENT, seat: Demo::Seat::INSTRUCTOR)

    expect(response).to have_http_status(:not_found)
  end

  it "does not know a run it did not lay down" do
    spend(CaseAction::CONSULT_CLIENT, run: "whatever")

    expect(response).to have_http_status(:not_found)
  end
end
