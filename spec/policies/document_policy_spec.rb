# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentPolicy, type: :policy do

  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_student) { build_stubbed(:user, role: :student) }
  let(:document_creator) { build_stubbed(:user, role: :student) }

  let(:case_record) { build_stubbed(:case) }
  let(:team) { build_stubbed(:team) }
  let(:case_document) { build_stubbed(:document, documentable: case_record, created_by_id: document_creator.id, status: "draft") }
  let(:team_document) { build_stubbed(:document, documentable: team, created_by_id: document_creator.id, status: "final") }

  before do
    # Mock policy interactions
    allow(CasePolicy).to receive(:new).and_return(double(show?: true, update?: true))
    allow(TeamPolicy).to receive(:new).and_return(double(show?: true, update?: true))
  end

  describe '#index?' do
    it 'permits access for all users' do
      policy = described_class.new(admin, case_document)
      expect(policy.index?).to be true
      policy = described_class.new(instructor, case_document)
      expect(policy.index?).to be true
      policy = described_class.new(student, case_document)
      expect(policy.index?).to be true
    end
  end

  describe '#show?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_document)
      expect(policy.show?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(document_creator, case_document)
      expect(policy.show?).to be true
    end

    it 'permits access when user can access documentable' do
      policy = described_class.new(student, case_document)
      expect(policy.show?).to be true
    end

    it 'denies access when user cannot access documentable' do
      allow(CasePolicy).to receive(:new).and_return(double(show?: false))
      policy = described_class.new(other_student, case_document)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it 'permits creation when user can access documentable' do
      policy = described_class.new(student, case_document)
      expect(policy.create?).to be true
    end

    it 'denies creation when user cannot access documentable' do
      allow(CasePolicy).to receive(:new).and_return(double(show?: false))
      policy = described_class.new(other_student, case_document)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_document)
      expect(policy.update?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(document_creator, case_document)
      expect(policy.update?).to be true
    end

    it 'permits access when user can update documentable' do
      policy = described_class.new(student, case_document)
      expect(policy.update?).to be true
    end

    it 'denies access when user cannot update documentable' do
      allow(CasePolicy).to receive(:new).and_return(double(update?: false))
      policy = described_class.new(other_student, case_document)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it 'permits admin access' do
      policy = described_class.new(admin, case_document)
      expect(policy.destroy?).to be true
    end

    it 'permits creator access' do
      policy = described_class.new(document_creator, case_document)
      expect(policy.destroy?).to be true
    end

    it 'permits access when user can update documentable' do
      policy = described_class.new(student, case_document)
      expect(policy.destroy?).to be true
    end

    it 'denies access when user cannot update documentable' do
      allow(CasePolicy).to receive(:new).and_return(double(update?: false))
      policy = described_class.new(other_student, case_document)
      expect(policy.destroy?).to be false
    end
  end

  describe '#finalize?' do
    it 'permits finalization of draft documents when user can manage' do
      policy = described_class.new(admin, case_document)
      expect(policy.finalize?).to be true
      policy = described_class.new(document_creator, case_document)
      expect(policy.finalize?).to be true
    end

    it 'denies finalization of non-draft documents' do
      policy = described_class.new(admin, team_document) # status is "final"
      expect(policy.finalize?).to be false
    end

    it 'denies finalization when user cannot manage' do
      allow(CasePolicy).to receive(:new).and_return(double(update?: false))
      policy = described_class.new(other_student, case_document)
      expect(policy.finalize?).to be false
    end
  end

  describe '#archive?' do
    it 'permits archiving of final documents when user can manage' do
      policy = described_class.new(admin, team_document)
      expect(policy.archive?).to be true
      policy = described_class.new(document_creator, team_document)
      expect(policy.archive?).to be true
    end

    it 'denies archiving of non-final documents' do
      policy = described_class.new(admin, case_document) # status is "draft"
      expect(policy.archive?).to be false
    end

    it 'denies archiving when user cannot manage' do
      allow(TeamPolicy).to receive(:new).and_return(double(update?: false))
      policy = described_class.new(other_student, team_document)
      expect(policy.archive?).to be false
    end
  end

  describe 'private methods' do
    let(:policy) { described_class.new(student, case_document) }

    describe '#user_can_access_documentable?' do
      it 'delegates to CasePolicy for Case documentables' do
        case_policy = double('CasePolicy')
        expect(CasePolicy).to receive(:new).with(student, case_record).and_return(case_policy)
        expect(case_policy).to receive(:show?).and_return(true)

        expect(policy.send(:user_can_access_documentable?)).to be true
      end

      it 'delegates to TeamPolicy for Team documentables' do
        policy = described_class.new(student, team_document)
        team_policy = double('TeamPolicy')
        expect(TeamPolicy).to receive(:new).with(student, team).and_return(team_policy)
        expect(team_policy).to receive(:show?).and_return(false)

        expect(policy.send(:user_can_access_documentable?)).to be false
      end

      it 'returns false for unknown documentable types' do
        unknown_document = build_stubbed(:document, documentable_type: 'Unknown')
        policy = described_class.new(student, unknown_document)

        expect(policy.send(:user_can_access_documentable?)).to be false
      end
    end
  end

  describe DocumentPolicy::Scope do
    let(:scope) { Document }
    let(:policy_scope) { DocumentPolicy::Scope.new(user, scope) }

    context 'when user is admin or instructor' do
      it 'returns all documents for admin' do
        policy_scope = DocumentPolicy::Scope.new(admin, scope)
        expect(scope).to receive(:all)
        policy_scope.resolve
      end

      it 'returns all documents for instructor' do
        policy_scope = DocumentPolicy::Scope.new(instructor, scope)
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context 'when user is student' do
      let(:user) { student }
      let(:case_ids) { [ 1, 2, 3 ] }
      let(:team_ids) { [ 4, 5, 6 ] }

      before do
        teams_double = double('teams')
        allow(teams_double).to receive(:joins).with(:cases).and_return(double(pluck: case_ids))
        allow(user).to receive_messages(teams: teams_double, team_ids: team_ids)
      end

      it 'returns documents for accessible cases, teams, and own documents' do
        expect(scope).to receive(:where).with(
          "(documentable_type = 'Case' AND documentable_id IN (?)) OR " \
          "(documentable_type = 'Team' AND documentable_id IN (?)) OR " \
          "created_by_id = ?",
          case_ids, team_ids, user.id
        )

        policy_scope.resolve
      end
    end

    context 'when user has no role' do
      let(:user) { build_stubbed(:user, role: nil) }

      it 'returns no documents' do
        expect(scope).to receive(:none)
        policy_scope.resolve
      end
    end
  end
end
