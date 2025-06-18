# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Application Accessibility', :accessibility, type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }

  before do
    driven_by :rack_test # Use rack_test for faster accessibility testing
  end

  describe 'Authentication pages' do
    it 'login page is accessible' do
      visit new_user_session_path
      expect_accessible_page
    end

    it 'registration page is accessible' do
      visit new_user_registration_path
      expect_accessible_page
    end

    it 'forgot password page is accessible' do
      visit new_user_password_path
      expect_accessible_page
    end
  end

  describe 'Student dashboard accessibility' do
    before do
      course = create(:course, instructor: instructor, organization: organization)
      case_obj = create(:case, course: course)
      team = create(:team, course: course)
      create(:case_team, case: case_obj, team: team)
      create(:team_member, user: user, team: team, role: 'member')
      create(:course_enrollment, user: user, course: course, status: 'active')

      sign_in user
    end

    it 'student dashboard is accessible' do
      visit dashboard_path
      check_authenticated_page_accessibility
    end

    it 'cases index is accessible' do
      visit cases_path
      check_authenticated_page_accessibility
    end

    it 'team management is accessible' do
      visit teams_path
      check_authenticated_page_accessibility
    end
  end

  describe 'Instructor dashboard accessibility' do
    before do
      course = create(:course, instructor: instructor, organization: organization)
      sign_in instructor
    end

    it 'instructor dashboard is accessible' do
      visit dashboard_path
      check_authenticated_page_accessibility
    end

    it 'courses management is accessible' do
      visit courses_path
      check_authenticated_page_accessibility
    end

    it 'course creation form is accessible' do
      visit new_course_path
      expect_accessible_form
    end
  end

  describe 'Case simulation accessibility' do
    let(:course) { create(:course, instructor: instructor, organization: organization) }
    let(:case_obj) { create(:case, course: course) }
    let(:team) { create(:team, course: course) }

    before do
      create(:case_team, case: case_obj, team: team)
      create(:team_member, user: user, team: team, role: 'member')
      create(:course_enrollment, user: user, course: course, status: 'active')
      sign_in user
    end

    it 'case details page is accessible' do
      visit case_path(case_obj)
      check_authenticated_page_accessibility
    end

    it 'evidence vault is accessible' do
      visit case_evidence_vault_index_path(case_obj)
      check_authenticated_page_accessibility
    end

    it 'negotiations interface is accessible' do
      visit case_negotiations_path(case_obj)
      check_authenticated_page_accessibility
    end
  end

  describe 'Form accessibility' do
    before { sign_in user }

    it 'case creation form is accessible' do
      course = create(:course, instructor: instructor, organization: organization)
      create(:course_enrollment, user: user, course: course, status: 'active')

      visit new_case_path(course_id: course.id)
      expect_accessible_form
    end

    it 'team creation form is accessible' do
      course = create(:course, instructor: instructor, organization: organization)
      create(:course_enrollment, user: user, course: course, status: 'active')

      visit new_team_path(course_id: course.id)
      expect_accessible_form
    end
  end

  describe 'Navigation accessibility' do
    before { sign_in user }

    it 'main navigation is accessible' do
      visit dashboard_path
      expect_accessible_navigation
    end

    it 'sidebar navigation is accessible' do
      visit dashboard_path
      expect(page).to be_accessible.within('[data-testid="sidebar-navigation"]').according_to(:wcag2a, :wcag2aa)
    end
  end

  describe 'Error pages accessibility' do
    it '404 page is accessible' do
      visit '/non-existent-page'
      expect_accessible_page
    end
  end
end
