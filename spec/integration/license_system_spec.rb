# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "License System Integration", type: :model do
  before do
    # Enable license enforcement for these tests
    allow(Rails.application.config).to receive(:skip_license_enforcement).and_return(false)
  end

  describe "Basic license creation and validation" do
    it "creates a valid free license" do
      license = License.new(
        organization_name: "Test University",
        contact_email: "admin@test.edu",
        license_type: "free"
      )

      expect(license).to be_valid
      expect(license.save).to be true
      expect(license.license_key).to be_present
      expect(license.signature).to be_present
    end

    it "creates default free license" do
      default_license = License.default_free_license
      expect(default_license).to be_persisted
      expect(default_license.license_type).to eq('free')
      expect(default_license.valid_signature?).to be true
    end
  end

  describe "Organization and license integration" do
    let(:organization) { create(:organization, name: "Test Org", domain: "test.edu", slug: "test") }

    it "assigns default license to organization" do
      expect(organization.license).to be_present
      expect(organization.license.license_type).to eq('free')
    end

    it "respects license limits for free tier" do
      # Free license allows 1 instructor, 3 students, 1 course
      license = organization.effective_license
      expect(license.max_instructors).to eq(1)
      expect(license.max_students).to eq(3)
      expect(license.max_courses).to eq(1)
    end
  end

  describe "License enforcement in practice" do
    let(:organization) { create(:organization, name: "Test Org", domain: "test.edu", slug: "test") }
    let(:starter_license) {
      License.create!(
        organization_name: organization.name,
        contact_email: "admin@test.edu",
        license_type: "starter",
        max_instructors: 2,
        max_students: 5,
        max_courses: 3,
        signature: "dummy_signature_for_test"
      )
    }

    before do
      organization.update!(license: starter_license)
    end

    it "allows creating users within limits" do
      instructor = build(:user, role: 'instructor', organization: organization)
      expect(instructor).to be_valid
      expect(instructor.save).to be true
    end

    it "allows creating courses within limits" do
      instructor = create(:user, role: 'instructor', organization: organization)
      course = build(:course, organization: organization, instructor: instructor)
      expect(course).to be_valid
      expect(course.save).to be true
    end

    it "provides accurate usage summary" do
      instructor = create(:user, role: 'instructor', organization: organization)
      create_list(:user, 2, role: 'student', organization: organization)
      create(:course, organization: organization, instructor: instructor)

      summary = organization.usage_summary
      expect(summary[:instructors][:count]).to eq(1)
      expect(summary[:students][:count]).to eq(2)
      expect(summary[:courses][:count]).to eq(1)
    end

    it "reports when within limits" do
      instructor = create(:user, role: 'instructor', organization: organization)
      create(:user, role: 'student', organization: organization)

      expect(organization.within_license_limits?).to be true
      expect(organization.license_status).to eq('valid')
    end
  end

  describe "License upgrade scenarios" do
    let(:organization) { create(:organization, name: "Test Org", domain: "test.edu", slug: "test") }

    it "can upgrade from free to paid license" do
      # Start with free license
      expect(organization.effective_license.license_type).to eq('free')

      # Create and assign paid license
      pro_license = License.create!(
        organization_name: organization.name,
        contact_email: "admin@test.edu",
        license_type: "professional",
        max_instructors: 5,
        max_students: 100,
        max_courses: 20,
        signature: "dummy_signature_for_test"
      )

      organization.update!(license: pro_license)

      expect(organization.effective_license.license_type).to eq('professional')
      expect(organization.can_add_user?('instructor')).to be true
    end

    it "enables features based on license type" do
      pro_license = License.create!(
        organization_name: organization.name,
        contact_email: "admin@test.edu",
        license_type: "professional",
        max_instructors: 5,
        max_students: 100,
        max_courses: 20,
        signature: "dummy_signature_for_test"
      )

      organization.update!(license: pro_license)

      expect(organization.feature_enabled?('advanced_analytics')).to be true
      expect(organization.feature_enabled?('custom_branding')).to be true
    end
  end
end
