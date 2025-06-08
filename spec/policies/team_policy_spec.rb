# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamPolicy, type: :policy do
  subject { described_class }

  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:team_owner) { build_stubbed(:user, role: :student) }
  let(:team_manager) { build_stubbed(:user, role: :student) }
  let(:other_student) { build_stubbed(:user, role: :student) }

  let(:team) { build_stubbed(:team, owner_id: team_owner.id, max_members: 5) }

  before do
    # Mock team relationships
    allow(team_owner).to receive(:teams).and_return([ team ])
    allow(other_student).to receive(:teams).and_return([])

    # Mock team_members for counting and role checking
    team_members_double = double('team_members')
    allow(team).to receive(:team_members).and_return(team_members_double)
    allow(team_members_double).to receive(:count).and_return(3)

    # Mock manager role checking
    manager_team_members = double('manager_team_members')
    allow(team_manager).to receive(:team_members).and_return(manager_team_members)
    allow(manager_team_members).to receive(:exists?).with(team: team, role: :manager).and_return(true)

    allow(student).to receive_messages(teams: [ team ], team_members: double(exists?: false))
  end

  permissions :index? do
    it 'permits access for all users' do
      expect(subject).to permit(admin, team)
      expect(subject).to permit(instructor, team)
      expect(subject).to permit(student, team)
    end
  end

  permissions :show? do
    it 'permits admin access' do
      expect(subject).to permit(admin, team)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, team)
    end

    it 'permits owner access' do
      expect(subject).to permit(team_owner, team)
    end

    it 'permits team member access' do
      expect(subject).to permit(student, team)
    end

    it 'denies access to non-members' do
      expect(subject).not_to permit(other_student, team)
    end
  end

  permissions :create? do
    it 'permits admin to create teams' do
      expect(subject).to permit(admin, Team)
    end

    it 'permits instructor to create teams' do
      expect(subject).to permit(instructor, Team)
    end

    it 'denies student access to create teams' do
      expect(subject).not_to permit(student, Team)
    end
  end

  permissions :update?, :destroy? do
    it 'permits admin access' do
      expect(subject).to permit(admin, team)
    end

    it 'permits owner access' do
      expect(subject).to permit(team_owner, team)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, team)
    end

    it 'permits team manager access' do
      expect(subject).to permit(team_manager, team)
    end

    it 'denies regular member access' do
      expect(subject).not_to permit(student, team)
    end

    it 'denies non-member access' do
      expect(subject).not_to permit(other_student, team)
    end
  end

  permissions :join? do
    context 'when user is student' do
      it 'permits joining if not already member and team has space' do
        expect(subject).to permit(other_student, team)
      end

      it 'denies joining if already a member' do
        expect(subject).not_to permit(student, team)
      end

      it 'denies joining if team is full' do
        allow(team.team_members).to receive(:count).and_return(5)
        expect(subject).not_to permit(other_student, team)
      end
    end

    context 'when user is not student' do
      it 'denies admin joining teams' do
        expect(subject).not_to permit(admin, team)
      end

      it 'denies instructor joining teams' do
        expect(subject).not_to permit(instructor, team)
      end
    end
  end

  permissions :leave? do
    context 'when user is student' do
      it 'permits leaving if member of team' do
        expect(subject).to permit(student, team)
      end

      it 'denies leaving if not member of team' do
        expect(subject).not_to permit(other_student, team)
      end
    end

    context 'when user is not student' do
      it 'denies admin leaving teams' do
        expect(subject).not_to permit(admin, team)
      end

      it 'denies instructor leaving teams' do
        expect(subject).not_to permit(instructor, team)
      end
    end
  end

  describe TeamPolicy::Scope do
    let(:scope) { Team }
    let(:policy_scope) { described_class::Scope.new(user, scope) }

    context 'when user is admin or instructor' do
      it 'returns all teams for admin' do
        policy_scope = described_class::Scope.new(admin, scope)
        expect(scope).to receive(:all)
        policy_scope.resolve
      end

      it 'returns all teams for instructor' do
        policy_scope = described_class::Scope.new(instructor, scope)
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context 'when user is student' do
      let(:user) { student }

      it 'returns only teams user is member of' do
        joined_scope = double('joined_scope')
        expect(scope).to receive(:joins).with(:team_members).and_return(joined_scope)
        expect(joined_scope).to receive(:where).with(team_members: { user_id: user.id })

        policy_scope.resolve
      end
    end

    context 'when user has no role' do
      let(:user) { build_stubbed(:user, role: nil) }

      it 'returns no teams' do
        expect(scope).to receive(:none)
        policy_scope.resolve
      end
    end
  end
end
