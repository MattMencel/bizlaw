# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CasePolicy, type: :policy do
  subject { described_class }

  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_student) { build_stubbed(:user, role: :student) }

  let(:case_record) { build_stubbed(:case, created_by_id: instructor.id) }
  let(:team) { build_stubbed(:team) }
  let(:case_team) { build_stubbed(:case_team, case: case_record, team: team) }

  before do
    allow(student).to receive(:teams).and_return(double(joins: double(exists?: true)))
    allow(student).to receive(:team_ids).and_return([team.id])
    allow(other_student).to receive(:teams).and_return(double(joins: double(exists?: false)))
    allow(other_student).to receive(:team_ids).and_return([])
  end

  permissions :index? do
    it 'permits access for all users' do
      expect(subject).to permit(admin, case_record)
      expect(subject).to permit(instructor, case_record)
      expect(subject).to permit(student, case_record)
    end
  end

  permissions :show? do
    it 'permits admin access' do
      expect(subject).to permit(admin, case_record)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, case_record)
    end

    it 'permits creator access' do
      expect(subject).to permit(instructor, case_record)
    end

    it 'permits student access when on assigned team' do
      expect(subject).to permit(student, case_record)
    end

    it 'denies student access when not on assigned team' do
      expect(subject).not_to permit(other_student, case_record)
    end
  end

  permissions :create? do
    it 'permits admin to create cases' do
      expect(subject).to permit(admin, Case)
    end

    it 'permits instructor to create cases' do
      expect(subject).to permit(instructor, Case)
    end

    it 'denies student access to create cases' do
      expect(subject).not_to permit(student, Case)
    end
  end

  permissions :update?, :destroy? do
    it 'permits admin access' do
      expect(subject).to permit(admin, case_record)
    end

    it 'permits creator access' do
      expect(subject).to permit(instructor, case_record)
    end

    it 'permits instructor access' do
      other_instructor = build_stubbed(:user, role: :instructor)
      expect(subject).to permit(other_instructor, case_record)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, case_record)
    end
  end

  describe CasePolicy::Scope do
    let(:scope) { Case }
    let(:policy_scope) { described_class::Scope.new(user, scope) }

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
