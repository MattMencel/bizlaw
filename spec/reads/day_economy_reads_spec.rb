# frozen_string_literal: true

require "rails_helper"

# What the Day's economy is allowed to tell a Team about itself.
#
# A Team is shown what it has left **today** and never a cumulative unspent
# total: roughly an eighth of the Budget expires unspent by design, so a running
# waste figure would grade a Team on a number the design requires of it. The
# Docket names who acted and carries no per-member totals, because a shared
# record that ranks the people in it is a leaderboard.
RSpec.describe "the Day's economy read surfaces" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:student) { a_user(organization: simulation.section.organization) }

  def spend(kind, on:, by: student)
    Days::Command.apply(act: :spend, side: side, day: on, by: by, kind: kind)
  end

  describe "the Budget read" do
    it "returns what is left today" do
      day = simulation.days.first
      spend(CaseAction::DEPOSE_WITNESS, on: day)

      expect(side.budget_on(day).remaining_in(DayBudget::PREPARATION)).to eq(5)
    end

    it "carries nothing from yesterday into today" do
      spend(CaseAction::RETAIN_EXPERT, on: simulation.days.first)
      Days::Open.call(simulation.days.second)

      expect(side.budget_on(simulation.days.second).remaining_in(DayBudget::PREPARATION)).to eq(8)
    end

    it "raises rather than answering for a half it does not hold" do
      expect { side.budget_on(simulation.days.first).remaining_in("goodwill") }
        .to raise_error(ArgumentError, /unknown half/)
    end
  end

  describe "the Docket read" do
    it "shows what was spent, by whom, and the Day each result lands" do
      spend(CaseAction::CONSULT_CLIENT, on: simulation.days.first)
      spend(CaseAction::DEPOSE_WITNESS, on: simulation.days.first)

      expect(side.docket_entries.map { |entry|
        [entry.kind, entry.cost, entry.spent_by.name, entry.lands_on_day.ordinal]
      }).to eq([
        [CaseAction::CONSULT_CLIENT, 1, student.name, 1],
        [CaseAction::DEPOSE_WITNESS, 3, student.name, 3]
      ])
    end

    it "reads in the order it was written, which forward is the Team's calendar" do
      spend(CaseAction::REQUEST_DOCUMENTS, on: simulation.days.first)
      spend(CaseAction::CONSULT_CLIENT, on: simulation.days.first)

      expect(side.docket_entries.map(&:id)).to eq(side.docket_entries.map(&:id).sort)
    end
  end

  # No interface can accidentally show a figure no object computes, so the
  # refusal is asserted against the objects rather than against a screen.
  describe "the figures no read exposes" do
    # A vocabulary rather than a list of methods: what the design refuses is the
    # *figure*, so a reader that arrives later under any of these names is caught
    # whatever object it hangs off.
    let(:cumulative) { /unspent|cumulative|lifetime|wasted|expired|contribution|leaderboard/ }
    let(:per_member_total) { /\A(spend|spent|cost|points)_(by|per)_(member|user|student)/ }

    it "exposes no cumulative unspent total on any object in the Day's economy" do
      surfaces = [DayBudget, DocketEntry, Side, Day, Simulation, CaseAction, Days::Command]

      offenders = surfaces.flat_map { |surface|
        (surface.instance_methods(false) + surface.singleton_methods(false))
          .grep(cumulative)
          .map { |method| "#{surface}##{method}" }
      }

      expect(offenders).to be_empty
    end

    it "defines no such reader anywhere under app/" do
      offenders = Rails.root.glob("app/**/*.rb").flat_map { |file|
        file.readlines.grep(/^\s*def (self\.)?\w*(#{cumulative.source})\w*/)
          .map { |line| "#{file.relative_path_from(Rails.root)}: #{line.strip}" }
      }

      expect(offenders).to be_empty
    end

    it "carries no per-member total on the Docket" do
      offenders = DocketEntry.instance_methods(false).grep(per_member_total)

      expect(offenders).to be_empty
    end

    it "holds no column that sums a Team's Days" do
      columns = ActiveRecord::Base.connection.columns("day_budgets").map(&:name) +
        ActiveRecord::Base.connection.columns("docket_entries").map(&:name)

      expect(columns.grep(cumulative)).to be_empty
    end
  end
end
