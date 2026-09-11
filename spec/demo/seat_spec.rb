# frozen_string_literal: true

require "rails_helper"

# There is no authentication, no session and no `Current.user`, so something has
# to turn a demo URL into the `(user, side)` pair every act needs. This is that
# something, and what is under test is the resolution alone: who is reading, and
# which Side they are reading as.
RSpec.describe Demo::Seat do
  let(:laid) { Demo::Seed.call }

  let(:simulation) { laid.demo }

  def seat(segment) = described_class.for(simulation, segment)

  describe "the player's seat" do
    # #332 settled that the player is the plaintiff, alone. The URL `rake
    # demo:seed` prints names a run and nothing else, so the bare form has to
    # mean him.
    it "is what the bare form resolves to" do
      resolved = seat(nil)

      expect(resolved.user.email).to eq(Demo::Seed::PLAYER_EMAIL)
      expect(resolved.side).to eq(simulation.plaintiff_side)
    end

    it "is also addressable by name, so the seated form is not a special case" do
      expect(seat(Side::PLAINTIFF)).to eq(seat(nil))
    end
  end

  # The second tab. It acts as a different person on the opposing Side, which
  # is the whole of what makes the Acceptance and the waiver demonstrable.
  describe "the defendant's seat" do
    it "seats the defendant's lead on the opposing Side" do
      resolved = seat(Side::DEFENDANT)

      expect(resolved.user.email).to eq(Demo::Seed::DEFENDANT_LEAD_EMAIL)
      expect(resolved.side).to eq(simulation.defendant_side)
    end

    # Ray is cast without a seat. He acts — he files the defendant's Day 2 and
    # seconds its Day 3 commit — but he holds no tab: the Second is named on
    # the control from `seconders_other_than`, not addressed by a URL.
    it "does not seat the teammate who seconds" do
      expect { seat("ray") }.to raise_error(described_class::UnknownSeat)
    end
  end

  # The Instructor is not a player. `CONTEXT.md` says so outright, and the shape
  # says it too: this is the one seat with no Side of its own, because the Side
  # a waiver is granted to is chosen per act rather than sat in.
  describe "the Instructor's seat" do
    it "seats the Instructor over no Side" do
      resolved = seat(described_class::INSTRUCTOR)

      expect(resolved.user.email).to eq(Demo::Seed::INSTRUCTOR_EMAIL)
      expect(resolved.side).to be_nil
    end

    it "says it is not a player rather than leaving callers to test the nil" do
      expect(seat(described_class::INSTRUCTOR)).not_to be_seated
      expect(seat(Side::DEFENDANT)).to be_seated
    end
  end

  it "does not know a seat the seed did not lay down" do
    expect { seat("whatever") }.to raise_error(described_class::UnknownSeat)
  end

  # The invariant the whole demo rests on, and the one a seat could quietly
  # break: `Side#members` folds from Attribution, and a second attributed
  # plaintiff makes the countersignature block live and deletes the waiver
  # demo. Seating people writes nothing, so it cannot.
  it "seats nobody onto a Side by resolving them" do
    expect { described_class::SEGMENTS.each_key { |segment| seat(segment) } }
      .not_to change { simulation.plaintiff_side.members.count }.from(1)
  end
end
