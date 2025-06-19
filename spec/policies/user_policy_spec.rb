# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_user) { build_stubbed(:user, role: :student) }

  describe "#index?" do
    it "permits admin access" do
      policy = described_class.new(admin, other_user)
      expect(policy.index?).to be true
    end

    it "permits instructor access" do
      policy = described_class.new(instructor, other_user)
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
end
