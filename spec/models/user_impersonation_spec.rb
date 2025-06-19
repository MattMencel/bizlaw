# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Impersonation", type: :model do
  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, role: :admin, organization: organization) }
  let(:instructor_user) { create(:user, role: :instructor, organization: organization) }
  let(:student_user) { create(:user, role: :student, organization: organization) }
  let(:other_student) { create(:user, role: :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor_user, organization: organization) }

  before do
    # Directly create course enrollment to avoid timestamp validation issues
    CourseEnrollment.create!(
      user: student_user,
      course: course,
      enrolled_at: Time.current,
      status: "active",
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  describe "#can_impersonate?" do
    context "when user is admin" do
      it "can impersonate any other user" do
        expect(admin_user.can_impersonate?(student_user)).to be true
        expect(admin_user.can_impersonate?(instructor_user)).to be true
        expect(admin_user.can_impersonate?(other_student)).to be true
      end

      it "cannot impersonate themselves" do
        expect(admin_user.can_impersonate?(admin_user)).to be false
      end
    end

    context "when user is instructor" do
      it "can impersonate students in their courses" do
        expect(instructor_user.can_impersonate?(student_user)).to be true
      end

      it "cannot impersonate students not in their courses" do
        expect(instructor_user.can_impersonate?(other_student)).to be false
      end

      it "cannot impersonate other instructors" do
        other_instructor = create(:user, role: :instructor, organization: organization)
        expect(instructor_user.can_impersonate?(other_instructor)).to be false
      end

      it "cannot impersonate admins" do
        expect(instructor_user.can_impersonate?(admin_user)).to be false
      end

      it "cannot impersonate themselves" do
        expect(instructor_user.can_impersonate?(instructor_user)).to be false
      end
    end

    context "when user is student" do
      it "cannot impersonate anyone" do
        expect(student_user.can_impersonate?(other_student)).to be false
        expect(student_user.can_impersonate?(instructor_user)).to be false
        expect(student_user.can_impersonate?(admin_user)).to be false
      end
    end
  end

  describe "#students_i_can_impersonate" do
    context "when user is admin" do
      it "returns all students" do
        expect(admin_user.students_i_can_impersonate).to include(student_user, other_student)
      end
    end

    context "when user is instructor" do
      it "returns only students enrolled in their courses" do
        expect(instructor_user.students_i_can_impersonate).to include(student_user)
        expect(instructor_user.students_i_can_impersonate).not_to include(other_student)
      end
    end

    context "when user is student" do
      it "returns no students" do
        expect(student_user.students_i_can_impersonate).to be_empty
      end
    end
  end

  describe "User roles and permissions" do
    it "allows admin users to have admin role" do
      expect(admin_user.admin?).to be true
    end

    it "allows student users to have student role" do
      expect(student_user.student?).to be true
    end

    it "allows instructor users to have instructor role" do
      expect(instructor_user.instructor?).to be true
    end
  end

  describe "User factory" do
    it "creates valid users" do
      expect(admin_user).to be_valid
      expect(student_user).to be_valid
      expect(instructor_user).to be_valid
    end
  end
end
