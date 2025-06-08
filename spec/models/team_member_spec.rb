# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMember, type: :model do
  subject(:team_member) { build(:team_member) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe "associations" do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
  end

  # Validations
  describe "validations" do
    it { is_expected.to validate_presence_of(:team_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:team_id).with_message("is already a member of this team") }

    describe "team membership limit" do
      let(:team) { create(:team, max_members: 2) }
      let(:user) { create(:user) }

      before do
        create_list(:team_member, 2, team: team)
      end

      it "validates against exceeding team member limit" do
        team_member = build(:team_member, team: team, user: user)
        expect(team_member).not_to be_valid
        expect(team_member.errors[:base]).to include("Team has reached maximum member limit")
      end
    end

    describe "owner role restriction" do
      let(:team) { create(:team) }
      let(:user) { create(:user) }

      it "prevents assigning owner role through team membership" do
        team_member = build(:team_member, team: team, user: user, role: :owner)
        expect(team_member).not_to be_valid
        expect(team_member.errors[:role]).to include("cannot be set to owner")
      end
    end

    describe "team capacity validation" do
      let(:team) { create(:team, max_members: 1) }
      let!(:existing_member) { create(:team_member, team: team) }
      let(:new_member) { build(:team_member, team: team) }

      it "prevents adding members beyond team capacity" do
        expect(new_member).not_to be_valid
        expect(new_member.errors[:base]).to include("Team has reached maximum member capacity")
      end
    end

    describe "owner role change validation" do
      let(:owner) { create(:user) }
      let(:team) { create(:team, owner: owner) }
      let(:team_member) { create(:team_member, team: team, user: owner, role: :manager) }

      it "prevents changing the owner's role" do
        team_member.role = :member
        expect(team_member).not_to be_valid
        expect(team_member.errors[:role]).to include("cannot be changed for team owner")
      end
    end
  end

  # Enums
  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(member: "member", manager: "manager").with_prefix(true) }
  end

  # Scopes
  describe "scopes" do
    let!(:manager) { create(:team_member, role: :manager) }
    let!(:member) { create(:team_member, role: :member) }
    let!(:deleted_member) { create(:team_member, :soft_deleted) }

    describe ".managers" do
      it "returns only manager team members" do
        expect(described_class.managers).to include(manager)
        expect(described_class.managers).not_to include(member)
      end
    end

    describe ".members" do
      it "returns only regular team members" do
        expect(described_class.members).to include(member)
        expect(described_class.members).not_to include(manager)
      end
    end

    describe ".by_role" do
      it "returns team members with specified role" do
        expect(described_class.by_role(:manager)).to include(manager)
        expect(described_class.by_role(:manager)).not_to include(member)
      end
    end

    describe ".active_in_team" do
      let(:team) { create(:team) }
      let!(:active_member) { create(:team_member, team: team) }
      let!(:deleted_member) { create(:team_member, :soft_deleted, team: team) }

      it "returns only active members in the specified team" do
        expect(described_class.active_in_team(team)).to include(active_member)
        expect(described_class.active_in_team(team)).not_to include(deleted_member)
      end
    end

    describe ".for_user" do
      let(:user) { create(:user) }
      let!(:user_membership) { create(:team_member, user: user) }
      let!(:other_membership) { create(:team_member) }

      it "returns team memberships for the specified user" do
        expect(described_class.for_user(user)).to include(user_membership)
        expect(described_class.for_user(user)).not_to include(other_membership)
      end
    end

    describe ".active" do
      it "returns only active team members" do
        expect(described_class.active).to include(manager, member)
        expect(described_class.active).not_to include(deleted_member)
      end
    end
  end

  # Instance methods
  describe "#manager?" do
    it "returns true for manager role" do
      team_member.role = :manager
      expect(team_member).to be_manager
    end

    it "returns false for member role" do
      team_member.role = :member
      expect(team_member).not_to be_manager
    end
  end

  describe "#display_name" do
    it "returns formatted name with role" do
      user = create(:user, first_name: "John", last_name: "Doe")
      team_member.user = user
      team_member.role = :manager
      expect(team_member.display_name).to eq("John Doe (manager)")
    end
  end

  # Callbacks
  describe "callbacks" do
    describe "before_destroy" do
      let(:team) { create(:team) }
      let(:owner) { team.owner }
      let(:team_member) { create(:team_member, team: team, user: owner) }

      it "prevents destroying team owner's membership" do
        expect(team_member.destroy).to be false
        expect(team_member.errors[:base]).to include("Cannot remove team owner's membership")
      end
    end
  end

  # Custom validations
  describe "#validate_not_team_owner" do
    let(:team) { create(:team) }
    let(:owner) { team.owner }

    it "prevents creating membership for team owner" do
      team_member = build(:team_member, team: team, user: owner)
      expect(team_member).not_to be_valid
      expect(team_member.errors[:user]).to include("is the team owner and cannot be added as a member")
    end
  end

  describe "#validate_team_not_full" do
    let(:team) { create(:team, max_members: 2) }

    before do
      create_list(:team_member, 2, team: team)
    end

    it "prevents adding members to full team" do
      team_member = build(:team_member, team: team)
      expect(team_member).not_to be_valid
      expect(team_member.errors[:base]).to include("Team has reached maximum member limit")
    end
  end
end
