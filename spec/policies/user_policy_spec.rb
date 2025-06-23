# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { build_stubbed(:user, :admin) }
  let(:instructor) { build_stubbed(:user, :instructor) }
  let(:student) { build_stubbed(:user, :student) }
  let(:other_user) { build_stubbed(:user, :student) }
  let(:org_admin) { build_stubbed(:user, :org_admin) }

  describe "#index?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.index?).to be true
    end

    it "permits instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.index?).to be true
    end

    it "permits org_admin access" do
      policy = described_class.new(org_admin, other_user)
      expect(policy.index?).to be true
    end

    it "denies student access" do
      policy = described_class.new(student, other_user)
      expect(policy.index?).to be false
    end
  end

  describe "#show?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.show?).to be true
    end

    it "permits instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.show?).to be true
    end

    it "permits student to see themselves" do
      policy = described_class.new(student, student)
      expect(policy.show?).to be true
    end

    it "denies student access to other users" do
      policy = described_class.new(student, other_user)
      expect(policy.show?).to be false
    end
  end

  describe "#create?" do
    it "permits admin access" do
      policy = described_class.new(admin, User)
      expect(policy.create?).to be true
    end

    it "denies instructor access" do
      policy = described_class.new(instructor, User)
      expect(policy.create?).to be false
    end

    it "denies student access" do
      policy = described_class.new(student, User)
      expect(policy.create?).to be false
    end
  end

  describe "#update?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.update?).to be true
    end

    it "permits user to update themselves" do
      policy = described_class.new(student, student)
      expect(policy.update?).to be true
    end

    it "denies user to update others" do
      policy = described_class.new(student, other_user)
      expect(policy.update?).to be false
    end
  end

  describe "#destroy?" do
    it "permits admin to destroy other users" do
      policy = described_class.new(admin, other_user)
      expect(policy.destroy?).to be true
    end

    it "denies admin to destroy themselves" do
      policy = described_class.new(admin, admin)
      expect(policy.destroy?).to be false
    end

    it "denies instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.destroy?).to be false
    end

    it "denies student access" do
      policy = described_class.new(student, other_user)
      expect(policy.destroy?).to be false
    end
  end

  describe "#impersonate?" do
    let(:organization) { create(:organization) }
    let(:admin) { create(:user, role: :admin, organization: organization) }
    let(:instructor) { create(:user, role: :instructor, organization: organization) }
    let(:student) { create(:user, role: :student, organization: organization) }
    let(:other_student) { create(:user, role: :student, organization: organization) }
    let(:course) { create(:course, instructor: instructor, organization: organization) }

    before do
      # Directly create course enrollment to avoid timestamp validation issues
      CourseEnrollment.create!(
        user: student,
        course: course,
        enrolled_at: Time.current,
        status: "active",
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    it "permits admin to impersonate other users" do
      policy = described_class.new(admin, student)
      expect(policy.impersonate?).to be true
      policy = described_class.new(admin, instructor)
      expect(policy.impersonate?).to be true
    end

    it "denies admin to impersonate themselves" do
      policy = described_class.new(admin, admin)
      expect(policy.impersonate?).to be false
    end

    it "permits instructor to impersonate students in their courses" do
      policy = described_class.new(instructor, student)
      expect(policy.impersonate?).to be true
    end

    it "denies instructor to impersonate students not in their courses" do
      policy = described_class.new(instructor, other_student)
      expect(policy.impersonate?).to be false
    end

    it "denies instructor to impersonate other instructors" do
      other_instructor = create(:user, role: :instructor, organization: organization)
      policy = described_class.new(instructor, other_instructor)
      expect(policy.impersonate?).to be false
    end

    it "denies student access" do
      policy = described_class.new(student, other_student)
      expect(policy.impersonate?).to be false
    end
  end

  describe "#stop_impersonation?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.stop_impersonation?).to be true
    end

    it "permits instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.stop_impersonation?).to be true
    end

    it "denies student access" do
      policy = described_class.new(student, other_user)
      expect(policy.stop_impersonation?).to be false
    end
  end

  describe "#enable_full_permissions?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.enable_full_permissions?).to be true
    end

    it "denies instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.enable_full_permissions?).to be false
    end

    it "denies student access" do
      policy = described_class.new(student, other_user)
      expect(policy.enable_full_permissions?).to be false
    end
  end

  describe "#disable_full_permissions?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.disable_full_permissions?).to be true
    end

    it "denies instructor access" do
      policy = described_class.new(instructor, other_user)
      expect(policy.disable_full_permissions?).to be false
    end

    it "denies student access" do
      policy = described_class.new(student, other_user)
      expect(policy.disable_full_permissions?).to be false
    end
  end

  describe UserPolicy::Scope do
    let(:organization1) { create(:organization, name: "University 1") }
    let(:organization2) { create(:organization, name: "University 2") }

    let(:admin) { create(:user, :admin, organization: organization1) }
    let(:instructor) { create(:user, :instructor, organization: organization1) }
    let(:student) { create(:user, :student, organization: organization1) }
    let(:org_admin) { create(:user, :org_admin, organization: organization1) }

    # Users in same organization
    let(:same_org_student) { create(:user, :student, organization: organization1) }
    let(:same_org_instructor) { create(:user, :instructor, organization: organization1) }

    # Users in different organization
    let(:other_org_student) { create(:user, :student, organization: organization2) }
    let(:other_org_instructor) { create(:user, :instructor, organization: organization2) }
    let(:other_org_admin) { create(:user, :org_admin, organization: organization2) }

    # User with no organization
    let(:no_org_user) { create(:user, :student, organization: nil) }

    let(:scope) { User }

    before do
      # Create test users
      admin
      instructor
      student
      org_admin
      same_org_student
      same_org_instructor
      other_org_student
      other_org_instructor
      other_org_admin
      no_org_user
    end

    describe "when user is admin" do
      let(:policy_scope) { UserPolicy::Scope.new(admin, scope) }

      it "returns all users" do
        resolved_users = policy_scope.resolve
        expect(resolved_users).to include(admin, instructor, student, org_admin, same_org_student, same_org_instructor, other_org_student, other_org_instructor, other_org_admin, no_org_user)
        expect(resolved_users.count).to eq(User.count)
      end
    end

    describe "when user is instructor" do
      let(:policy_scope) { UserPolicy::Scope.new(instructor, scope) }

      it "returns all users" do
        resolved_users = policy_scope.resolve
        expect(resolved_users).to include(admin, instructor, student, org_admin, same_org_student, same_org_instructor, other_org_student, other_org_instructor, other_org_admin, no_org_user)
        expect(resolved_users.count).to eq(User.count)
      end
    end

    describe "when user is org_admin (without admin role)" do
      let(:policy_scope) { UserPolicy::Scope.new(org_admin, scope) }

      it "returns only users in the same organization" do
        resolved_users = policy_scope.resolve
        expect(resolved_users).to include(admin, instructor, student, org_admin, same_org_student, same_org_instructor)
        expect(resolved_users).not_to include(other_org_student, other_org_instructor, other_org_admin, no_org_user)
        expect(resolved_users.count).to eq(6) # admin, instructor, student, org_admin, same_org_student, same_org_instructor
      end

      it "filters by organization_id correctly" do
        resolved_users = policy_scope.resolve
        organization_ids = resolved_users.pluck(:organization_id).uniq
        expect(organization_ids).to eq([organization1.id])
      end
    end

    describe "when user is org_admin with admin role" do
      let(:admin_org_admin) { create(:user, role: :admin, roles: ["admin", "org_admin"], organization: organization1) }
      let(:policy_scope) { UserPolicy::Scope.new(admin_org_admin, scope) }

      it "returns all users (admin privileges take precedence)" do
        resolved_users = policy_scope.resolve
        expect(resolved_users.count).to eq(User.count)
      end
    end

    describe "when org_admin has no organization" do
      let(:org_admin_no_org) { create(:user, :org_admin, organization: nil) }
      let(:policy_scope) { UserPolicy::Scope.new(org_admin_no_org, scope) }

      it "returns no users" do
        resolved_users = policy_scope.resolve
        expect(resolved_users.count).to eq(0)
      end
    end

    describe "when user is student" do
      let(:policy_scope) { UserPolicy::Scope.new(student, scope) }
      let(:course) { create(:course, instructor: same_org_instructor, organization: organization1) }
      let(:team) { create(:team, course: course, owner: student) }

      before do
        # Enroll the student in the course first
        create(:course_enrollment, user: student, course: course, status: :active)

        # Create team memberships
        create(:team_member, user: student, team: team)
        create(:team_member, user: same_org_student, team: team)
      end

      it "returns only themselves and their teammates" do
        resolved_users = policy_scope.resolve
        expect(resolved_users).to include(student, same_org_student)
        expect(resolved_users).not_to include(admin, instructor, org_admin, same_org_instructor, other_org_student, other_org_instructor, other_org_admin, no_org_user)
        expect(resolved_users.count).to eq(2)
      end
    end

    describe "when user has no valid role" do
      let(:no_role_user) { create(:user, :student, roles: ["student"]) }
      let(:policy_scope) { UserPolicy::Scope.new(no_role_user, scope) }

      before do
        # Manually clear roles to simulate having no roles (testing edge case)
        no_role_user.update_column(:roles, [])
        no_role_user.update_column(:role, nil)
      end

      it "returns no users" do
        resolved_users = policy_scope.resolve
        expect(resolved_users.count).to eq(0)
      end
    end
  end
end
