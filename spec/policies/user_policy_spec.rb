# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_user) { build_stubbed(:user, role: :student) }

  permissions :index? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, other_user)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :show? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, other_user)
    end

    it 'permits student to see themselves' do
      expect(subject).to permit(student, student)
    end

    it 'denies student access to other users' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :create? do
    it 'permits admin access' do
      expect(subject).to permit(admin, User)
    end

    it 'denies instructor access' do
      expect(subject).not_to permit(instructor, User)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, User)
    end
  end

  permissions :update? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'permits user to update themselves' do
      expect(subject).to permit(student, student)
    end

    it 'denies user to update others' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :destroy? do
    it 'permits admin to destroy other users' do
      expect(subject).to permit(admin, other_user)
    end

    it 'denies admin to destroy themselves' do
      expect(subject).not_to permit(admin, admin)
    end

    it 'denies instructor access' do
      expect(subject).not_to permit(instructor, other_user)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :impersonate? do
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
        status: 'active',
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    it 'permits admin to impersonate other users' do
      expect(subject).to permit(admin, student)
      expect(subject).to permit(admin, instructor)
    end

    it 'denies admin to impersonate themselves' do
      expect(subject).not_to permit(admin, admin)
    end

    it 'permits instructor to impersonate students in their courses' do
      expect(subject).to permit(instructor, student)
    end

    it 'denies instructor to impersonate students not in their courses' do
      expect(subject).not_to permit(instructor, other_student)
    end

    it 'denies instructor to impersonate other instructors' do
      other_instructor = create(:user, role: :instructor, organization: organization)
      expect(subject).not_to permit(instructor, other_instructor)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_student)
    end
  end

  permissions :stop_impersonation? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'permits instructor access' do
      expect(subject).to permit(instructor, other_user)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :enable_full_permissions? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'denies instructor access' do
      expect(subject).not_to permit(instructor, other_user)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_user)
    end
  end

  permissions :disable_full_permissions? do
    it 'permits admin access' do
      expect(subject).to permit(admin, other_user)
    end

    it 'denies instructor access' do
      expect(subject).not_to permit(instructor, other_user)
    end

    it 'denies student access' do
      expect(subject).not_to permit(student, other_user)
    end
  end
end
