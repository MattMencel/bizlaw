# frozen_string_literal: true

require "rails_helper"

RSpec.describe PerformanceScore, type: :model do
  let(:organization) { create(:organization) }
  let(:course) { create(:course, organization: organization) }
  let(:case_record) { create(:case, course: course) }
  let(:simulation) { create(:simulation, case: case_record) }
  let(:team) { create(:team, course: course) }
  let(:user) { create(:user, :student, organization: organization) }

  describe "associations" do
    it { is_expected.to belong_to(:simulation) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe "validations" do
    subject { build(:performance_score, simulation: simulation, team: team, user: user) }

    it { is_expected.to validate_presence_of(:total_score) }
    it { is_expected.to validate_presence_of(:scored_at) }
    it { is_expected.to validate_presence_of(:score_type) }
    it { is_expected.to validate_presence_of(:score_breakdown) }

    it { is_expected.to validate_numericality_of(:total_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
    it { is_expected.to validate_inclusion_of(:score_type).in_array(%w[individual team]) }

    it { is_expected.to validate_numericality_of(:settlement_quality_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(40).allow_nil }
    it { is_expected.to validate_numericality_of(:legal_strategy_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(30).allow_nil }
    it { is_expected.to validate_numericality_of(:collaboration_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(20).allow_nil }
    it { is_expected.to validate_numericality_of(:efficiency_score).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10).allow_nil }

    describe "score type validations" do
      context "for individual scores" do
        subject { build(:performance_score, :individual_score, simulation: simulation, team: team, user: user) }

        it "requires a user" do
          subject.user = nil
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to include("must be present for individual scores")
        end

        it "requires user to be a team member" do
          other_user = create(:user, :student, organization: organization)
          subject.user = other_user
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to include("must be a member of the specified team")
        end
      end

      context "for team scores" do
        subject { build(:performance_score, :team_score, simulation: simulation, team: team) }

        it "does not have a user" do
          subject.user = user
          expect(subject).not_to be_valid
          expect(subject.errors[:user]).to include("must be absent for team scores")
        end
      end
    end
  end

  describe "scopes" do
    let!(:individual_score) { create(:performance_score, :individual_score, simulation: simulation, team: team, user: user) }
    let!(:team_score) { create(:performance_score, :team_score, simulation: simulation, team: team) }
    let!(:high_score) { create(:performance_score, :high_performer, simulation: simulation, team: team, user: create(:user, :student, organization: organization)) }

    describe ".individual_scores" do
      it "returns only individual scores" do
        expect(PerformanceScore.individual_scores).to include(individual_score, high_score)
        expect(PerformanceScore.individual_scores).not_to include(team_score)
      end
    end

    describe ".team_scores" do
      it "returns only team scores" do
        expect(PerformanceScore.team_scores).to include(team_score)
        expect(PerformanceScore.team_scores).not_to include(individual_score, high_score)
      end
    end

    describe ".top_performers" do
      it "orders by total_score descending" do
        expect(PerformanceScore.top_performers.first).to eq(high_score)
      end
    end

    describe ".for_simulation" do
      let(:other_simulation) { create(:simulation, case: create(:case, course: course)) }
      let!(:other_score) { create(:performance_score, simulation: other_simulation, team: team, user: user) }

      it "filters by simulation" do
        scores = PerformanceScore.for_simulation(simulation)
        expect(scores).to include(individual_score, team_score, high_score)
        expect(scores).not_to include(other_score)
      end
    end
  end

  describe "instance methods" do
    let(:performance_score) do
      create(:performance_score,
        simulation: simulation,
        team: team,
        user: user,
        settlement_quality_score: 32,
        legal_strategy_score: 24,
        collaboration_score: 16,
        efficiency_score: 8,
        speed_bonus: 5,
        creative_terms_score: 3
      )
    end

    describe "#individual_score?" do
      it "returns true for individual scores" do
        performance_score.score_type = "individual"
        expect(performance_score.individual_score?).to be true
      end

      it "returns false for team scores" do
        performance_score.score_type = "team"
        expect(performance_score.individual_score?).to be false
      end
    end

    describe "#team_score?" do
      it "returns true for team scores" do
        performance_score.score_type = "team"
        expect(performance_score.team_score?).to be true
      end

      it "returns false for individual scores" do
        performance_score.score_type = "individual"
        expect(performance_score.team_score?).to be false
      end
    end

    describe "#calculate_total_score!" do
      it "calculates total from component scores" do
        performance_score.calculate_total_score!

        expected_total = 32 + 24 + 16 + 8 + 5 + 3
        expect(performance_score.total_score).to eq(expected_total)
      end

      it "handles nil component scores" do
        performance_score.update(settlement_quality_score: nil, legal_strategy_score: nil)
        performance_score.calculate_total_score!

        expected_total = 0 + 0 + 16 + 8 + 5 + 3
        expect(performance_score.total_score).to eq(expected_total)
      end

      it "builds score breakdown" do
        performance_score.calculate_total_score!

        expect(performance_score.score_breakdown).to include(
          "settlement_quality" => hash_including("score" => 32, "max_points" => 40),
          "legal_strategy" => hash_including("score" => 24, "max_points" => 30),
          "collaboration" => hash_including("score" => 16, "max_points" => 20)
        )
      end
    end

    describe "#performance_grade" do
      it "returns A for scores 90-100" do
        performance_score.total_score = 95
        expect(performance_score.performance_grade).to eq("A")
      end

      it "returns B for scores 80-89" do
        performance_score.total_score = 85
        expect(performance_score.performance_grade).to eq("B")
      end

      it "returns C for scores 70-79" do
        performance_score.total_score = 75
        expect(performance_score.performance_grade).to eq("C")
      end

      it "returns D for scores 60-69" do
        performance_score.total_score = 65
        expect(performance_score.performance_grade).to eq("D")
      end

      it "returns F for scores below 60" do
        performance_score.total_score = 55
        expect(performance_score.performance_grade).to eq("F")
      end
    end

    describe "#performance_summary" do
      before { performance_score.calculate_total_score! }

      it "includes all summary components" do
        summary = performance_score.performance_summary

        expect(summary).to include(
          :grade,
          :total_score,
          :strengths,
          :improvement_areas,
          :breakdown
        )
      end

      it "identifies strengths correctly" do
        summary = performance_score.performance_summary

        # Settlement Quality: 32/40 = 80% (strength threshold)
        # Legal Strategy: 24/30 = 80% (strength threshold)
        expect(summary[:strengths]).to include("Settlement Strategy", "Legal Reasoning")
      end

      it "identifies improvement areas correctly" do
        performance_score.update(collaboration_score: 10, efficiency_score: 4)
        performance_score.calculate_total_score!
        summary = performance_score.performance_summary

        # Collaboration: 10/20 = 50% (below 60% threshold)
        # Efficiency: 4/10 = 40% (below 60% threshold)
        expect(summary[:improvement_areas]).to include("Team Collaboration", "Process Efficiency")
      end
    end

    describe "#rank_in_simulation" do
      let!(:other_users) { create_list(:user, 3, :student, organization: organization) }
      let!(:other_scores) do
        other_users.map.with_index do |user, index|
          create(:performance_score,
            simulation: simulation,
            team: team,
            user: user,
            total_score: 70 + (index * 10) # Scores: 70, 80, 90
          )
        end
      end

      before { create(:team_member, team: team, user: other_users.first)
create(:team_member, team: team, user: other_users.second)
create(:team_member, team: team, user: other_users.third)  }

      it "calculates rank correctly" do
        performance_score.update(total_score: 85)
        expect(performance_score.rank_in_simulation).to eq(2) # 90 > 85 > 80 > 70
      end

      it "handles ties correctly" do
        performance_score.update(total_score: 80)
        expect(performance_score.rank_in_simulation).to eq(3) # 90 > 80 (tie) > 70
      end
    end

    describe "#percentile_in_simulation" do
      let!(:other_users) { create_list(:user, 4, :student, organization: organization) }
      let!(:other_scores) do
        other_users.map.with_index do |user, index|
          create(:performance_score,
            simulation: simulation,
            team: team,
            user: user,
            total_score: 60 + (index * 10) # Scores: 60, 70, 80, 90
          )
        end
      end

      before do
        other_users.each { |user| create(:team_member, team: team, user: user) }
      end

      it "calculates percentile correctly" do
        performance_score.update(total_score: 75)
        # Scores: 60, 70, 75, 80, 90
        # 75 is greater than 60, 70 (2 out of 5) = 40th percentile
        expect(performance_score.percentile_in_simulation).to eq(40.0)
      end

      it "handles single score" do
        PerformanceScore.where.not(id: performance_score.id).destroy_all
        expect(performance_score.percentile_in_simulation).to eq(100)
      end
    end
  end

  describe "class methods" do
    describe ".calculate_team_score!" do
      let!(:team_members) { create_list(:user, 3, :student, organization: organization) }
      let!(:individual_scores) do
        team_members.map.with_index do |user, index|
          create(:team_member, team: team, user: user)
          create(:performance_score,
            simulation: simulation,
            team: team,
            user: user,
            settlement_quality_score: 25 + (index * 5),
            legal_strategy_score: 20 + (index * 3),
            collaboration_score: 15 + (index * 2),
            efficiency_score: 7 + index
          )
        end
      end

      it "calculates team score from individual averages" do
        team_score = PerformanceScore.calculate_team_score!(simulation, team)

        expect(team_score.settlement_quality_score).to eq(30.0) # (25 + 30 + 35) / 3
        expect(team_score.legal_strategy_score).to eq(23.0) # (20 + 23 + 26) / 3
        expect(team_score.collaboration_score).to eq(17.0) # (15 + 17 + 19) / 3
        expect(team_score.efficiency_score).to eq(8.0) # (7 + 8 + 9) / 3
      end

      it "creates team score record" do
        expect {
          PerformanceScore.calculate_team_score!(simulation, team)
        }.to change(PerformanceScore, :count).by(1)

        team_score = PerformanceScore.team_scores.last
        expect(team_score.simulation).to eq(simulation)
        expect(team_score.team).to eq(team)
        expect(team_score.user).to be_nil
        expect(team_score.score_type).to eq("team")
      end

      it "updates existing team score" do
        existing_team_score = create(:performance_score, :team_score,
          simulation: simulation, team: team, total_score: 50)

        expect {
          PerformanceScore.calculate_team_score!(simulation, team)
        }.not_to change(PerformanceScore, :count)

        existing_team_score.reload
        expect(existing_team_score.total_score).not_to eq(50)
      end

      it "returns nil when no individual scores exist" do
        PerformanceScore.individual_scores.destroy_all
        expect(PerformanceScore.calculate_team_score!(simulation, team)).to be_nil
      end
    end

    describe ".calculate_individual_score!" do
      let!(:team_member) { create(:team_member, team: team, user: user) }

      it "calculates individual score using PerformanceCalculator" do
        calculator_double = instance_double(PerformanceCalculator)
        allow(PerformanceCalculator).to receive(:new).with(simulation, team, user).and_return(calculator_double)

        allow(calculator_double).to receive(:settlement_quality_score).and_return(32)
        allow(calculator_double).to receive(:legal_strategy_score).and_return(24)
        allow(calculator_double).to receive(:collaboration_score).and_return(16)
        allow(calculator_double).to receive(:efficiency_score).and_return(8)
        allow(calculator_double).to receive(:speed_bonus).and_return(5)
        allow(calculator_double).to receive(:creative_terms_score).and_return(3)

        score = PerformanceScore.calculate_individual_score!(simulation, team, user)

        expect(score.settlement_quality_score).to eq(32)
        expect(score.legal_strategy_score).to eq(24)
        expect(score.collaboration_score).to eq(16)
        expect(score.efficiency_score).to eq(8)
        expect(score.speed_bonus).to eq(5)
        expect(score.creative_terms_score).to eq(3)
      end

      it "creates individual score record" do
        allow_any_instance_of(PerformanceCalculator).to receive(:settlement_quality_score).and_return(30)
        allow_any_instance_of(PerformanceCalculator).to receive(:legal_strategy_score).and_return(25)
        allow_any_instance_of(PerformanceCalculator).to receive(:collaboration_score).and_return(18)
        allow_any_instance_of(PerformanceCalculator).to receive(:efficiency_score).and_return(9)
        allow_any_instance_of(PerformanceCalculator).to receive(:speed_bonus).and_return(0)
        allow_any_instance_of(PerformanceCalculator).to receive(:creative_terms_score).and_return(0)

        expect {
          PerformanceScore.calculate_individual_score!(simulation, team, user)
        }.to change(PerformanceScore, :count).by(1)

        score = PerformanceScore.individual_scores.last
        expect(score.simulation).to eq(simulation)
        expect(score.team).to eq(team)
        expect(score.user).to eq(user)
        expect(score.score_type).to eq("individual")
      end

      it "updates existing individual score" do
        existing_score = create(:performance_score, :individual_score,
          simulation: simulation, team: team, user: user, total_score: 50)

        allow_any_instance_of(PerformanceCalculator).to receive(:settlement_quality_score).and_return(35)
        allow_any_instance_of(PerformanceCalculator).to receive(:legal_strategy_score).and_return(28)
        allow_any_instance_of(PerformanceCalculator).to receive(:collaboration_score).and_return(18)
        allow_any_instance_of(PerformanceCalculator).to receive(:efficiency_score).and_return(9)
        allow_any_instance_of(PerformanceCalculator).to receive(:speed_bonus).and_return(5)
        allow_any_instance_of(PerformanceCalculator).to receive(:creative_terms_score).and_return(3)

        expect {
          PerformanceScore.calculate_individual_score!(simulation, team, user)
        }.not_to change(PerformanceScore, :count)

        existing_score.reload
        expect(existing_score.settlement_quality_score).to eq(35)
        expect(existing_score.total_score).not_to eq(50)
      end
    end
  end

  describe "delegated methods" do
    let(:performance_score) { build(:performance_score, simulation: simulation, team: team, user: user) }

    it "delegates case to simulation" do
      expect(performance_score.case).to eq(simulation.case)
    end
  end

  describe "timestamping" do
    let(:performance_score) { create(:performance_score, simulation: simulation, team: team, user: user) }

    it "sets scored_at on creation" do
      expect(performance_score.scored_at).to be_present
      expect(performance_score.scored_at).to be_within(1.second).of(Time.current)
    end
  end
end
