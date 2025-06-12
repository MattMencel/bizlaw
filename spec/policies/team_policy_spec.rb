# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamPolicy, type: :policy do
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

  describe '#index?' do
    it 'permits access for all users' do
      policy = described_class.new(admin, team)
      expect(policy.index?).to be true
      policy = described_class.new(instructor, team)
      expect(policy.index?).to be true
      policy = described_class.new(student, team)
      expect(policy.index?).to be true
    end
  end

  describe '#show?' do
    it 'permits admin access' do
      policy = described_class.new(admin, team)
      expect(policy.show?).to be true
    end

    it 'permits instructor access' do
      policy = described_class.new(instructor, team)
      expect(policy.show?).to be true
    end

    it 'permits owner access' do
      policy = described_class.new(team_owner, team)
      expect(policy.show?).to be true
    end

    it 'permits team member access' do
      policy = described_class.new(student, team)
      expect(policy.show?).to be true
    end

    it 'denies access to non-members' do
      policy = described_class.new(other_student, team)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it 'permits admin to create teams' do
      policy = described_class.new(admin, Team)
      expect(policy.create?).to be true
    end

    it 'permits instructor to create teams' do
      policy = described_class.new(instructor, Team)
      expect(policy.create?).to be true
    end

    it 'denies student access to create teams' do
      policy = described_class.new(student, Team)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    it 'permits admin access' do
      policy = described_class.new(admin, team)
      expect(policy.update?).to be true
    end

    it 'permits owner access' do
      policy = described_class.new(team_owner, team)
      expect(policy.update?).to be true
    end

    it 'permits instructor access' do
      policy = described_class.new(instructor, team)
      expect(policy.update?).to be true
    end

    it 'permits team manager access' do
      policy = described_class.new(team_manager, team)
      expect(policy.update?).to be true
    end

    it 'denies regular member access' do
      policy = described_class.new(student, team)
      expect(policy.update?).to be false
    end

    it 'denies non-member access' do
      policy = described_class.new(other_student, team)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it 'permits admin access' do
      policy = described_class.new(admin, team)
      expect(policy.destroy?).to be true
    end

    it 'permits owner access' do
      policy = described_class.new(team_owner, team)
      expect(policy.destroy?).to be true
    end

    it 'permits instructor access' do
      policy = described_class.new(instructor, team)
      expect(policy.destroy?).to be true
    end

    it 'permits team manager access' do
      policy = described_class.new(team_manager, team)
      expect(policy.destroy?).to be true
    end

    it 'denies regular member access' do
      policy = described_class.new(student, team)
      expect(policy.destroy?).to be false
    end

    it 'denies non-member access' do
      policy = described_class.new(other_student, team)
      expect(policy.destroy?).to be false
    end
  end

  describe '#join?' do
    context 'when user is student' do
      it 'permits joining if not already member and team has space' do
        policy = described_class.new(other_student, team)
        expect(policy.join?).to be true
      end

      it 'denies joining if already a member' do
        policy = described_class.new(student, team)
        expect(policy.join?).to be false
      end

      it 'denies joining if team is full' do
        allow(team.team_members).to receive(:count).and_return(5)
        policy = described_class.new(other_student, team)
        expect(policy.join?).to be false
      end
    end

    context 'when user is not student' do
      it 'denies admin joining teams' do
        policy = described_class.new(admin, team)
        expect(policy.join?).to be false
      end

      it 'denies instructor joining teams' do
        policy = described_class.new(instructor, team)
        expect(policy.join?).to be false
      end
    end
  end

  describe '#leave?' do
    context 'when user is student' do
      it 'permits leaving if member of team' do
        policy = described_class.new(student, team)
        expect(policy.leave?).to be true
      end

      it 'denies leaving if not member of team' do
        policy = described_class.new(other_student, team)
        expect(policy.leave?).to be false
      end
    end

    context 'when user is not student' do
      it 'denies admin leaving teams' do
        policy = described_class.new(admin, team)
        expect(policy.leave?).to be false
      end

      it 'denies instructor leaving teams' do
        policy = described_class.new(instructor, team)
        expect(policy.leave?).to be false
      end
    end
  end

  describe TeamPolicy::Scope do
    let(:scope) { Team }
    let(:policy_scope) { TeamPolicy::Scope.new(user, scope) }

    context 'when user is admin or instructor' do
      it 'returns all teams for admin' do
        policy_scope = TeamPolicy::Scope.new(admin, scope)
        expect(scope).to receive(:all)
        policy_scope.resolve
      end

      it 'returns all teams for instructor' do
        policy_scope = TeamPolicy::Scope.new(instructor, scope)
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
