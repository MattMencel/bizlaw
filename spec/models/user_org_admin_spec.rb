# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "orgAdmin functionality" do
    let(:organization) { create(:organization) }
    let!(:first_instructor) { create(:user, :instructor, organization: organization) }
    let(:instructor) { create(:user, :instructor, organization: organization) }
    let(:student) { create(:user, :student, organization: organization) }

    describe "#org_admin?" do
      it "returns false by default" do
        expect(instructor.org_admin?).to be false
      end

      it "returns true when org_admin is set" do
        instructor.add_role("org_admin")
        expect(instructor.org_admin?).to be true
      end
    end

    describe "#can_manage_organization?" do
      context "when user is admin" do
        let(:admin) { create(:user, :admin) }

        it "returns true for any organization" do
          expect(admin.can_manage_organization?(organization)).to be true
        end
      end

      context "when user is org_admin" do
        before { instructor.add_role("org_admin") }

        it "returns true for their organization" do
          expect(instructor.can_manage_organization?(organization)).to be true
        end

        it "returns false for different organization" do
          other_org = create(:organization)
          expect(instructor.can_manage_organization?(other_org)).to be false
        end
      end

      context "when user is regular instructor" do
        it "returns false" do
          expect(instructor.can_manage_organization?(organization)).to be false
        end
      end
    end

    describe "#can_assign_org_admin?" do
      context "when user is admin" do
        let(:admin) { create(:user, :admin, organization: organization) }

        it "returns true" do
          expect(admin.can_assign_org_admin?).to be true
        end
      end

      context "when user is org_admin" do
        before { instructor.add_role("org_admin") }

        it "returns true" do
          expect(instructor.can_assign_org_admin?).to be true
        end
      end

      context "when user is regular instructor" do
        it "returns false" do
          expect(instructor.can_assign_org_admin?).to be false
        end
      end
    end

    describe "first instructor auto-assignment" do
      context "when creating first instructor for organization" do
        it "automatically assigns as org_admin" do
          new_org = create(:organization)
          first_instructor = create(:user, :instructor, organization: new_org)

          expect(first_instructor.reload.org_admin?).to be true
        end
      end

      context "when creating second instructor for organization" do
        before { create(:user, :instructor, organization: organization, roles: ["instructor", "org_admin"]) }

        it "does not automatically assign as org_admin" do
          second_instructor = create(:user, :instructor, organization: organization)

          expect(second_instructor.org_admin?).to be false
        end
      end

      context "when creating student" do
        it "does not assign as org_admin" do
          expect(student.org_admin?).to be false
        end
      end
    end

    describe "scopes" do
      before do
        instructor.add_role("org_admin")
        create(:user, :instructor, organization: organization, roles: ["instructor"])
      end

      describe ".org_admins" do
        it "returns only org_admins" do
          org_admins = User.org_admins
          expect(org_admins).to include(instructor)
          expect(org_admins).to include(first_instructor)
          expect(org_admins.count).to eq 2  # first_instructor + instructor
        end
      end
    end
  end
end
