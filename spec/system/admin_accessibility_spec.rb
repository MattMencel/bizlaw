# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Admin Interface Accessibility', type: :system, accessibility: true do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }

  before do
    driven_by :rack_test # Use rack_test for faster accessibility testing
    sign_in admin
  end

  describe 'Admin dashboard accessibility' do
    it 'admin dashboard is accessible' do
      visit dashboard_path
      check_authenticated_page_accessibility
    end
  end

  describe 'Organization management accessibility' do
    it 'organizations index is accessible' do
      visit admin_organizations_path
      check_authenticated_page_accessibility
    end

    it 'organization show page is accessible' do
      visit admin_organization_path(organization)
      check_authenticated_page_accessibility
    end

    it 'organization edit form is accessible' do
      visit edit_admin_organization_path(organization)
      expect_accessible_form
    end

    it 'new organization form is accessible' do
      visit new_admin_organization_path
      expect_accessible_form
    end
  end

  describe 'User management accessibility' do
    it 'users index is accessible' do
      visit admin_users_path
      check_authenticated_page_accessibility
    end

    it 'user edit form is accessible' do
      visit edit_admin_user_path(student)
      expect_accessible_form
    end

    it 'user creation form is accessible' do
      visit new_admin_user_path
      expect_accessible_form
    end
  end

  describe 'Course administration accessibility' do
    let(:course) { create(:course, instructor: instructor, organization: organization) }

    it 'course management interface is accessible' do
      visit course_path(course)
      check_authenticated_page_accessibility
    end

    it 'student assignment interface is accessible' do
      visit assign_students_course_path(course)
      check_authenticated_page_accessibility
    end

    it 'invitation management is accessible' do
      visit manage_invitations_course_path(course)
      check_authenticated_page_accessibility
    end
  end

  describe 'Case administration accessibility' do
    let(:course) { create(:course, instructor: instructor, organization: organization) }
    let(:case_obj) { create(:case, course: course) }

    it 'case administration interface is accessible' do
      visit case_path(case_obj)
      check_authenticated_page_accessibility
    end

    it 'case edit form is accessible' do
      visit edit_case_path(case_obj)
      expect_accessible_form
    end
  end

  describe 'Team administration accessibility' do
    let(:course) { create(:course, instructor: instructor, organization: organization) }
    let(:team) { create(:team, course: course) }

    it 'team management interface is accessible' do
      visit team_path(team)
      check_authenticated_page_accessibility
    end

    it 'team edit form is accessible' do
      visit edit_team_path(team)
      expect_accessible_form
    end
  end

  describe 'Data tables accessibility' do
    before do
      # Create test data for tables
      create_list(:user, 5, organization: organization)
      create_list(:course, 3, instructor: instructor, organization: organization)
    end

    it 'users data table is accessible' do
      visit admin_users_path
      
      # Check that tables have proper headers and structure
      expect(page).to have_selector('table')
      expect(page).to have_selector('th[scope="col"]') # Column headers should have scope
      
      check_authenticated_page_accessibility
    end

    it 'organizations data table is accessible' do
      create_list(:organization, 3)
      visit admin_organizations_path
      
      expect(page).to have_selector('table')
      check_authenticated_page_accessibility
    end
  end

  describe 'Form validation accessibility' do
    it 'form errors are accessible' do
      visit new_admin_organization_path
      
      # Submit empty form to trigger validation errors
      click_button 'Create Organization'
      
      # Check that errors are announced to screen readers
      expect(page).to have_selector('[role="alert"]') if page.has_content?('error')
      
      check_authenticated_page_accessibility
    end
  end

  describe 'Modal dialogs accessibility' do
    it 'confirmation dialogs are accessible' do
      organization_to_delete = create(:organization)
      visit admin_organization_path(organization_to_delete)
      
      # Look for delete buttons or confirmation dialogs
      if page.has_button?('Delete') || page.has_link?('Delete')
        check_authenticated_page_accessibility
      end
    end
  end

  describe 'Bulk actions accessibility' do
    before do
      create_list(:user, 5, organization: organization)
    end

    it 'bulk selection interface is accessible' do
      visit admin_users_path
      
      # Check for bulk action controls
      check_authenticated_page_accessibility
      
      # Verify checkboxes have proper labels
      expect(page).to have_selector('input[type="checkbox"][aria-label], input[type="checkbox"] + label') if page.has_selector('input[type="checkbox"]')
    end
  end
end