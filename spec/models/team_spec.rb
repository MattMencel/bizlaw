# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team, type: :model do
  subject(:team) { build(:team) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User") }
    it { is_expected.to belong_to(:course).optional }
    it { is_expected.to have_many(:team_members).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:team_members) }
    it { is_expected.to have_many(:cases).dependent(:destroy) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
  end

  # Validations
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:owner_id) }
    it { is_expected.to validate_presence_of(:max_members) }
    it { is_expected.to validate_numericality_of(:max_members).is_greater_than(0) }

    it "validates uniqueness of name scoped to owner" do
      create(:team, name: "Test Team", owner: team.owner)
      team.name = "Test Team"
      expect(team).not_to be_valid
      expect(team.errors[:name]).to include("has already been taken")
    end
  end

  # Scopes
  describe "scopes" do
    let!(:active_team) { create(:team) }
    let!(:deleted_team) { create(:team, :soft_deleted) }
    let!(:full_team) { create(:team, :full) }
    let!(:team_with_cases) { create(:team, :with_cases) }

    describe ".by_owner" do
      it "returns teams owned by the specified user" do
        expect(described_class.by_owner(active_team.owner)).to include(active_team)
        expect(described_class.by_owner(active_team.owner)).not_to include(deleted_team)
      end
    end

    describe ".search_by_name" do
      let!(:alpha_team) { create(:team, name: "Alpha Team") }
      let!(:beta_team) { create(:team, name: "Beta Team") }

      it "finds teams by partial name match" do
        expect(described_class.search_by_name("alpha")).to include(alpha_team)
        expect(described_class.search_by_name("alpha")).not_to include(beta_team)
      end

      it "is case insensitive" do
        expect(described_class.search_by_name("ALPHA")).to include(alpha_team)
      end
    end

    describe ".with_member" do
      let(:user) { create(:user) }
      let!(:member_team) { create(:team, :with_members) }

      before do
        create(:team_member, team: member_team, user: user)
      end

      it "returns teams that include the specified user" do
        expect(described_class.with_member(user)).to include(member_team)
        expect(described_class.with_member(user)).not_to include(active_team)
      end
    end

    describe ".with_role" do
      let!(:team_with_manager) { create(:team, :with_managers) }

      it "returns teams that have members with the specified role" do
        expect(described_class.with_role("manager")).to include(team_with_manager)
        expect(described_class.with_role("manager")).not_to include(active_team)
      end
    end
  end

  # Instance methods
  describe "#member?" do
    let(:team) { create(:team) }
    let(:member) { create(:user) }

    before do
      create(:team_member, team: team, user: member)
    end

    it "returns true for team members" do
      expect(team.member?(member)).to be true
    end

    it "returns false for non-members" do
      expect(team.member?(create(:user))).to be false
    end
  end

  describe "#manager?" do
    let(:team) { create(:team) }
    let(:manager) { create(:user) }
    let(:member) { create(:user) }

    before do
      create(:team_member, team: team, user: manager, role: "manager")
      create(:team_member, team: team, user: member)
    end

    it "returns true for team managers" do
      expect(team.manager?(manager)).to be true
    end

    it "returns true for team owner" do
      expect(team.manager?(team.owner)).to be true
    end

    it "returns false for regular members" do
      expect(team.manager?(member)).to be false
    end
  end

  describe "#add_member" do
    let(:team) { create(:team) }
    let(:user) { create(:user) }

    it "adds a new member with the specified role" do
      expect { team.add_member(user, role: "manager") }
        .to change { team.team_members.count }.by(1)
      expect(team.team_members.last.role).to eq("manager")
    end

    it "returns false if user is already a member" do
      team.add_member(user)
      expect(team.add_member(user)).to be false
    end

    it "returns false if team is full" do
      team = create(:team, :full)
      expect(team.add_member(user)).to be false
    end
  end

  describe "#remove_member" do
    let(:team) { create(:team) }
    let(:member) { create(:user) }

    before do
      create(:team_member, team: team, user: member)
    end

    it "removes the member from the team" do
      expect { team.remove_member(member) }
        .to change { team.team_members.count }.by(-1)
    end

    it "returns false if trying to remove the owner" do
      expect(team.remove_member(team.owner)).to be false
    end
  end

  describe "#change_member_role" do
    let(:team) { create(:team) }
    let(:member) { create(:user) }

    before do
      create(:team_member, team: team, user: member)
    end

    it "changes the member's role" do
      expect(team.change_member_role(member, "manager")).to be_truthy
      expect(team.team_members.find_by(user: member).role).to eq("manager")
    end

    it "returns false if user is not a member" do
      expect(team.change_member_role(create(:user), "manager")).to be false
    end

    it "returns false if trying to change owner's role" do
      expect(team.change_member_role(team.owner, "manager")).to be false
    end
  end

  describe "#member_count" do
    it "returns the correct number of members" do
      team = create(:team, :with_members, members_count: 3)
      expect(team.member_count).to eq(3)
    end
  end

  describe "#full?" do
    it "returns true when team has reached max members" do
      team = create(:team, :full)
      expect(team).to be_full
    end

    it "returns false when team has space available" do
      team = create(:team, :with_members, members_count: 3)
      expect(team).not_to be_full
    end
  end

  # Callbacks
  describe "callbacks" do
    describe "#normalize_name" do
      it "strips whitespace from name" do
        team.name = " Test Team "
        team.valid?
        expect(team.name).to eq("Test Team")
      end
    end
  end

  describe "#validate_member_limit" do
    it "adds an error when member limit is exceeded" do
      team = build(:team, max_members: 2)
      3.times { team.team_members.build(user: create(:user)) }

      expect(team).not_to be_valid
      expect(team.errors[:base]).to include("Team has reached maximum member limit")
    end
  end

  describe "#has_student_members?" do
    let(:instructor) { create(:user, :instructor) }
    let(:course) { create(:course, instructor: instructor) }
    let(:student1) { create(:user, :student) }
    let(:student2) { create(:user, :student) }
    let(:team) { create(:team, course: course, owner: instructor) }

    context "with no members" do
      it "returns false" do
        expect(team.has_student_members?).to be false
      end
    end

    context "with only instructor members" do
      before do
        create(:team_member, team: team, user: instructor, role: :member)
      end

      it "returns false" do
        expect(team.has_student_members?).to be false
      end
    end

    context "with student members" do
      before do
        create(:team_member, team: team, user: student1, role: :member)
      end

      it "returns true" do
        expect(team.has_student_members?).to be true
      end
    end

    context "with mixed instructor and student members" do
      before do
        create(:team_member, team: team, user: instructor, role: :member)
        create(:team_member, team: team, user: student1, role: :member)
      end

      it "returns true when any member is a student" do
        expect(team.has_student_members?).to be true
      end
    end

    context "with multiple students" do
      before do
        create(:team_member, team: team, user: student1, role: :member)
        create(:team_member, team: team, user: student2, role: :manager)
      end

      it "returns true" do
        expect(team.has_student_members?).to be true
      end
    end
  end
end
