# frozen_string_literal: true

require "rails_helper"

RSpec.describe LicenseEnforcementService, type: :service do
  let(:organization) { create(:organization) }
  let(:license) { create(:license, max_instructors: 2, max_students: 5, max_courses: 3) }
  let(:service) { described_class.new(organization: organization) }

  before do
    organization.update!(license: license)
    # Enable license enforcement for testing
    allow(Rails.application.config).to receive(:skip_license_enforcement).and_return(false)
  end

  describe "#can_add_user?" do
    context "when within instructor limits" do
      before do
        create(:user, :instructor, organization: organization)
      end

      it "allows adding another instructor" do
        expect(service.can_add_user?("instructor")).to be true
      end
    end

    context "when at instructor limit" do
      before do
        create_list(:user, 2, :instructor, organization: organization)
      end

      it "prevents adding another instructor" do
        expect(service.can_add_user?("instructor")).to be false
      end
    end

    context "when within student limits" do
      before do
        create_list(:user, 3, :student, organization: organization)
      end

      it "allows adding another student" do
        expect(service.can_add_user?("student")).to be true
      end
    end

    context "when at student limit" do
      before do
        create_list(:user, 5, :student, organization: organization)
      end

      it "prevents adding another student" do
        expect(service.can_add_user?("student")).to be false
      end
    end

    context "when license enforcement is disabled" do
      before do
        allow(Rails.application.config).to receive(:skip_license_enforcement).and_return(true)
        create_list(:user, 10, :student, organization: organization)
      end

      it "always allows adding users" do
        expect(service.can_add_user?("student")).to be true
        expect(service.can_add_user?("instructor")).to be true
      end
    end
  end

  describe "#can_add_course?" do
    let(:instructor) { create(:user, :instructor, organization: organization) }

    context "when within course limits" do
      before do
        create_list(:course, 2, organization: organization, instructor: instructor)
      end

      it "allows adding another course" do
        expect(service.can_add_course?).to be true
      end
    end

    context "when at course limit" do
      before do
        create_list(:course, 3, organization: organization, instructor: instructor)
      end

      it "prevents adding another course" do
        expect(service.can_add_course?).to be false
      end
    end
  end

  describe "#license_status" do
    it "returns valid for active license within limits" do
      expect(service.license_status).to eq("valid")
    end

    it "returns expired for expired license" do
      license.update!(expires_at: 1.day.ago.to_date)
      expect(service.license_status).to eq("expired")
    end

    it "returns expiring_soon for soon-to-expire license" do
      license.update!(expires_at: 15.days.from_now.to_date)
      expect(service.license_status).to eq("expiring_soon")
    end

    it "returns over_limits when exceeding limits" do
      create_list(:user, 6, :student, organization: organization)
      expect(service.license_status).to eq("over_limits")
    end
  end

  describe "#grace_period_active?" do
    context "with expired license" do
      before do
        license.update!(expires_at: 15.days.ago.to_date)
      end

      it "returns true within 30-day grace period" do
        expect(service.grace_period_active?).to be true
      end
    end

    context "with license expired beyond grace period" do
      before do
        license.update!(expires_at: 45.days.ago.to_date)
      end

      it "returns false" do
        expect(service.grace_period_active?).to be false
      end
    end
  end

  describe "#enforce_user_limit!" do
    context "when within limits" do
      it "does not raise an error" do
        expect { service.enforce_user_limit!("instructor") }.not_to raise_error
      end
    end

    context "when over limits" do
      before do
        create_list(:user, 2, :instructor, organization: organization)
      end

      it "raises LicenseLimitExceeded error" do
        expect { service.enforce_user_limit!("instructor") }
          .to raise_error(LicenseEnforcementService::LicenseLimitExceeded)
      end
    end
  end

  describe "#enforce_course_limit!" do
    let(:instructor) { create(:user, :instructor, organization: organization) }

    context "when within limits" do
      before do
        create_list(:course, 2, organization: organization, instructor: instructor)
      end

      it "does not raise an error" do
        expect { service.enforce_course_limit! }.not_to raise_error
      end
    end

    context "when over limits" do
      before do
        create_list(:course, 3, organization: organization, instructor: instructor)
      end

      it "raises LicenseLimitExceeded error" do
        expect { service.enforce_course_limit! }
          .to raise_error(LicenseEnforcementService::LicenseLimitExceeded)
      end
    end
  end

  describe "#can_access_feature?" do
    context "with free license" do
      let(:license) { create(:license, license_type: "free") }

      it "denies access to premium features" do
        expect(service.can_access_feature?("advanced_analytics")).to be false
      end
    end

    context "with professional license" do
      let(:license) { create(:license, license_type: "professional") }

      it "allows access to professional features" do
        expect(service.can_access_feature?("advanced_analytics")).to be true
      end
    end
  end
end
