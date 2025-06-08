# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseTeam, type: :model do
  subject { build(:case_team) }

  describe 'concerns' do
    it_behaves_like 'has_uuid'
    it_behaves_like 'has_timestamps'
    it_behaves_like 'soft_deletable'
  end

  describe 'associations' do
    it { is_expected.to belong_to(:case) }
    it { is_expected.to belong_to(:team) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:role) }

    describe 'uniqueness validations' do
      let(:case_record) { create(:case) }
      let(:team1) { create(:team) }
      let(:team2) { create(:team) }

      context 'case_id uniqueness scoped to role' do
        it 'allows different teams for different roles in same case' do
          create(:case_team, case: case_record, team: team1, role: :plaintiff)
          case_team = build(:case_team, case: case_record, team: team2, role: :defendant)

          expect(case_team).to be_valid
        end

        it 'prevents multiple teams for same role in same case' do
          create(:case_team, case: case_record, team: team1, role: :plaintiff)
          case_team = build(:case_team, case: case_record, team: team2, role: :plaintiff)

          expect(case_team).not_to be_valid
          expect(case_team.errors[:case_id]).to include('should have only one team per role')
        end
      end

      context 'case_id uniqueness scoped to team_id' do
        it 'allows same team in different cases' do
          case1 = create(:case)
          case2 = create(:case)

          create(:case_team, case: case1, team: team1, role: :plaintiff)
          case_team = build(:case_team, case: case2, team: team1, role: :plaintiff)

          expect(case_team).to be_valid
        end

        it 'prevents same team assigned to same case multiple times' do
          create(:case_team, case: case_record, team: team1, role: :plaintiff)
          case_team = build(:case_team, case: case_record, team: team1, role: :defendant)

          expect(case_team).not_to be_valid
          expect(case_team.errors[:case_id]).to include('team already assigned to this case')
        end
      end
    end
  end

  describe 'enums' do
    it 'defines role enum with correct values' do
      expect(described_class.roles).to eq({
        'plaintiff' => 'plaintiff',
        'defendant' => 'defendant'
      })
    end

    it 'creates scopes for each role' do
      expect(described_class).to respond_to(:role_plaintiff)
      expect(described_class).to respond_to(:role_defendant)
    end

    it 'creates role query methods' do
      plaintiff_case_team = build(:case_team, role: :plaintiff)
      defendant_case_team = build(:case_team, role: :defendant)

      expect(plaintiff_case_team.role_plaintiff?).to be true
      expect(plaintiff_case_team.role_defendant?).to be false

      expect(defendant_case_team.role_defendant?).to be true
      expect(defendant_case_team.role_plaintiff?).to be false
    end
  end

  describe 'factory' do
    it 'creates valid case team' do
      expect(build(:case_team)).to be_valid
    end

    it 'creates case team with associations' do
      case_team = create(:case_team)
      expect(case_team.case).to be_present
      expect(case_team.team).to be_present
    end

    it 'creates case team with role' do
      case_team = create(:case_team, role: :defendant)
      expect(case_team.role).to eq('defendant')
      expect(case_team.role_defendant?).to be true
    end
  end

  describe 'business logic scenarios' do
    let(:case_record) { create(:case) }
    let(:plaintiff_team) { create(:team, name: 'Plaintiff Team') }
    let(:defendant_team) { create(:team, name: 'Defendant Team') }

    it 'supports complete case setup with both teams' do
      plaintiff_assignment = create(:case_team,
        case: case_record,
        team: plaintiff_team,
        role: :plaintiff
      )

      defendant_assignment = create(:case_team,
        case: case_record,
        team: defendant_team,
        role: :defendant
      )

      expect(case_record.case_teams.count).to eq(2)
      expect(case_record.case_teams.role_plaintiff.first).to eq(plaintiff_assignment)
      expect(case_record.case_teams.role_defendant.first).to eq(defendant_assignment)
    end
  end
end
