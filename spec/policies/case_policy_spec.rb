# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CasePolicy, type: :policy do
  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_student) { build_stubbed(:user, role: :student) }

  let(:case_record) { build_stubbed(:case, created_by_id: instructor.id) }
  let(:team) { build_stubbed(:team) }
  let(:case_team) { build_stubbed(:case_team, case: case_record, team: team) }

  before do
    allow(student).to receive_messages(teams: double(joins: double(exists?: true)), team_ids: [ team.id ])
    allow(other_student).to receive_messages(teams: double(joins: double(exists?: false)), team_ids: [])
  end

  describe '#index?' do
    it 'permits access for all users' do
      policy = described_class.new(admin, case_record)
      expect(policy.index?).to be true

      policy = described_class.new(instructor, case_record)
      expect(policy.index?).to be true

      policy = described_class.new(student, case_record)
      expect(policy.index?).to be true
    end
  end

  describe '#show?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_record)
      expect(policy.show?).to be true
    end

    it 'permits instructor access' do
      policy = described_class.new(instructor, case_record)
      expect(policy.show?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(instructor, case_record)
      expect(policy.show?).to be true
    end

    it 'permits student access when on assigned team' do
      policy = described_class.new(student, case_record)
      expect(policy.show?).to be true
    end

    it 'denies student access when not on assigned team' do
      policy = described_class.new(other_student, case_record)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it 'permits admin to create cases' do
      policy = described_class.new(admin, Case)
      expect(policy.create?).to be true
    end

    it 'permits instructor to create cases' do
      policy = described_class.new(instructor, Case)
      expect(policy.create?).to be true
    end

    it 'denies student access to create cases' do
      policy = described_class.new(student, Case)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_record)
      expect(policy.update?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(instructor, case_record)
      expect(policy.update?).to be true
    end

    it 'permits instructor access' do
      other_instructor = build_stubbed(:user, role: :instructor)
      policy = described_class.new(other_instructor, case_record)
      expect(policy.update?).to be true
    end

    it 'denies student access' do
      policy = described_class.new(student, case_record)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_record)
      expect(policy.destroy?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(instructor, case_record)
      expect(policy.destroy?).to be true
    end

    it 'permits instructor access' do
      other_instructor = build_stubbed(:user, role: :instructor)
      policy = described_class.new(other_instructor, case_record)
      expect(policy.destroy?).to be true
    end

    it 'denies student access' do
      policy = described_class.new(student, case_record)
      expect(policy.destroy?).to be false
    end
  end

  describe CasePolicy::Scope do
    let(:scope) { Case }
    let(:policy_scope) { CasePolicy::Scope.new(user, scope) }

    context 'when user is admin' do
      let(:user) { admin }

      it 'returns all cases' do
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context 'when user is instructor' do
      let(:user) { instructor }

      it 'returns all cases' do
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context 'when user is student' do
      let(:user) { student }

      it 'returns only cases for assigned teams' do
        assigned_teams_scope = double('assigned_teams_scope')
        expect(scope).to receive(:joins).with(:assigned_teams).and_return(assigned_teams_scope)
        expect(assigned_teams_scope).to receive(:where).with(teams: { id: user.team_ids })

        policy_scope.resolve
      end
    end

    context 'when user has no role' do
      let(:user) { build_stubbed(:user, role: nil) }

      it 'returns no cases' do
        expect(scope).to receive(:none)
        policy_scope.resolve
      end
    end
  end
end
