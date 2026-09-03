# frozen_string_literal: true

require "rails_helper"

# The single command seam every act in the Day enters through. Nothing else
# writes to the Day's ledgers, so this is where the rules are enforced and where
# the tests bind.
RSpec.describe Days::Command do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }
  let(:student) { a_user(organization: simulation.section.organization) }
  let(:budget) { side.budget_on(day) }

  def command_for(kind, on: day)
    described_class.new(act: :spend, side: side, day: on, by: student, kind: kind)
  end

  describe "#quote" do
    it "reports the cost, the half, what is left today and the Day the result lands" do
      quote = command_for(CaseAction::DEPOSE_WITNESS).quote

      expect(quote).to be_affordable
      expect(quote.cost).to eq(3)
      expect(quote.half).to eq(DayBudget::PREPARATION)
      expect(quote.remaining_after).to eq(5)
      expect(quote.landing_day).to eq(simulation.days.find_by(ordinal: 3))
    end

    it "lands a Consult on the Day it was bought" do
      quote = command_for(CaseAction::CONSULT_CLIENT).quote

      expect(quote.cost).to eq(1)
      expect(quote.landing_day).to eq(day)
    end

    it "writes no Docket row" do
      expect { command_for(CaseAction::RETAIN_EXPERT).quote }.not_to change(DocketEntry, :count)
    end

    it "moves no counter" do
      expect { command_for(CaseAction::RETAIN_EXPERT).quote }
        .not_to change { budget.reload.preparation_spent }
    end

    it "reports what is left after everything already spent today" do
      command_for(CaseAction::RETAIN_EXPERT).apply

      expect(command_for(CaseAction::REQUEST_DOCUMENTS).quote.remaining_after).to eq(1)
    end

    it "refuses an Action the preparation half cannot cover, rather than raising" do
      command_for(CaseAction::RETAIN_EXPERT).apply
      command_for(CaseAction::DEPOSE_WITNESS).apply

      quote = command_for(CaseAction::REQUEST_DOCUMENTS).quote

      expect(quote).to be_refused
      expect(quote.refusal).to eq(:the_budget_cannot_cover_it)
      # Nothing renders a negative Budget from a refusal.
      expect(quote.remaining_after).to be_nil
    end

    it "refuses an Action whose result would land past the Simulation's last Day" do
      quote = command_for(CaseAction::DEPOSE_WITNESS, on: simulation.days.last).quote

      expect(quote).to be_refused
      expect(quote.refusal).to eq(:the_result_would_land_past_the_last_day)
      expect(quote.landing_day).to be_nil
    end

    it "refuses a spend on a Day that has not opened, because it has no quota to draw on" do
      quote = command_for(CaseAction::CONSULT_CLIENT, on: simulation.days.second).quote

      expect(quote).to be_refused
      expect(quote.refusal).to eq(:the_day_has_not_opened)
    end

    it "raises on a kind the Case's Action menu does not author" do
      expect { command_for("subpoena_the_mayor").quote }
        .to raise_error(ArgumentError, /not on this Case's Action menu/)
    end
  end

  describe "#apply" do
    it "appends exactly one Docket row" do
      expect { command_for(CaseAction::REQUEST_DOCUMENTS).apply }
        .to change(DocketEntry, :count).by(1)
    end

    it "writes the Side, the Day, the kind, the cost, the half, the landing Day and who spent" do
      command_for(CaseAction::REQUEST_DOCUMENTS).apply

      entry = side.docket_entries.last
      expect(entry.kind).to eq(CaseAction::REQUEST_DOCUMENTS)
      expect(entry.side).to eq(side)
      expect(entry.day).to eq(day)
      expect(entry.spent_by).to eq(student)
      expect(entry.cost).to eq(2)
      expect(entry.half).to eq(DayBudget::PREPARATION)
      expect(entry.lands_on_day).to eq(simulation.days.find_by(ordinal: 2))
    end

    it "charges the preparation half and leaves the exchange half alone" do
      command_for(CaseAction::DEPOSE_WITNESS).apply

      expect(budget.reload.preparation_spent).to eq(3)
      expect(budget.exchange_spent).to eq(0)
    end

    # The confirmation a student reads is rendered from `quote`, so the number
    # they confirm has to be computed by the same code path that charges them.
    it "charges the number it quoted, whatever that number is" do
      command = command_for(CaseAction::DEPOSE_WITNESS)
      quote = command.quote

      entry = command.apply

      expect(entry.cost).to eq(quote.cost)
      expect(entry.half).to eq(quote.half)
      expect(entry.lands_on_day).to eq(quote.landing_day)
      expect(budget.reload.remaining_in(quote.half)).to eq(quote.remaining_after)
    end

    it "still charges the number it quoted once the Case reprices the Action" do
      command = command_for(CaseAction::DEPOSE_WITNESS)
      quote = command.quote

      simulation.case_version.actions.find_by!(kind: CaseAction::DEPOSE_WITNESS)
        .update!(cost: 4, lead_time_days: 3)
      entry = command.apply

      # The row records what was charged, not what the Action costs now.
      expect(entry.cost).to eq(3)
      expect(entry.cost).to eq(quote.cost)
      expect(entry.lands_on_day).to eq(quote.landing_day)
      expect(budget.reload.remaining_in(quote.half)).to eq(quote.remaining_after)
    end

    context "when the preparation half cannot cover the Action" do
      before do
        command_for(CaseAction::RETAIN_EXPERT).apply
        command_for(CaseAction::DEPOSE_WITNESS).apply
      end

      it "refuses it" do
        expect { command_for(CaseAction::REQUEST_DOCUMENTS).apply }
          .to raise_error(Days::Command::Refused, /the_budget_cannot_cover_it/)
      end

      it "appends no Docket row" do
        expect {
          begin
            command_for(CaseAction::REQUEST_DOCUMENTS).apply
          rescue Days::Command::Refused
            nil
          end
        }.not_to change(DocketEntry, :count)
      end

      it "leaves the Budget spent to exactly its ceiling and never past it" do
        expect(budget.reload.preparation_spent).to eq(8)
        expect(budget.remaining_in(DayBudget::PREPARATION)).to eq(0)
      end
    end

    it "refuses an Action whose result would land past the Simulation's last Day" do
      expect { command_for(CaseAction::DEPOSE_WITNESS, on: simulation.days.last).apply }
        .to raise_error(Days::Command::Refused, /the_result_would_land_past_the_last_day/)
    end

    # Reads are not serialized, so two members of one Side can both quote the
    # same half as affordable and only the second insert finds the ceiling. The
    # CHECK catches it either way; what this pins is that the loser gets the
    # refusal a caller can render rather than a database fault it cannot.
    context "when a teammate spends between this quote and this insert" do
      let(:mine) { command_for(CaseAction::RETAIN_EXPERT) }
      let(:theirs) { command_for(CaseAction::RETAIN_EXPERT) }

      before do
        mine.quote
        theirs.quote
        theirs.apply
      end

      it "refuses rather than raising the ceiling's own error" do
        # The quote it is holding still says affordable, so this is the CHECK
        # being caught at the insert and not the refusal before it.
        expect(mine.quote).to be_affordable

        expect { mine.apply }
          .to raise_error(Days::Command::Refused, /the_budget_cannot_cover_it/)
      end

      it "appends no Docket row" do
        expect {
          begin
            mine.apply
          rescue Days::Command::Refused
            nil
          end
        }.not_to change(DocketEntry, :count)
      end

      it "leaves the half where the teammate's spend left it" do
        begin
          mine.apply
        rescue Days::Command::Refused
          nil
        end

        expect(budget.reload.preparation_spent).to eq(5)
      end
    end

    it "carries the refusing quote on the refusal, so a caller can say why" do
      expect { command_for(CaseAction::DEPOSE_WITNESS, on: simulation.days.last).apply }
        .to raise_error(Days::Command::Refused) { |refusal|
          expect(refusal.quote.refusal).to eq(:the_result_would_land_past_the_last_day)
        }
    end
  end

  it "refuses an act it does not know" do
    expect { described_class.new(act: :settle_the_case, side: side, day: day, by: student) }
      .to raise_error(ArgumentError, /unknown act/)
  end
end
