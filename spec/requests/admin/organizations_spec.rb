# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Organizations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin_user) { create(:user, role: "admin") }
  let(:instructor_user) { create(:user, role: "instructor") }
  let(:student_user) { create(:user, role: "student") }
  let(:organization) { create(:organization) }

  describe "GET /admin/organizations" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns success" do
        get admin_organizations_path
        expect(response).to have_http_status(:success)
      end

      it "displays all organizations" do
        org1 = create(:organization, name: "Test University")
        org2 = create(:organization, name: "Another College")

        get admin_organizations_path

        expect(response.body).to include(org1.name)
        expect(response.body).to include(org2.name)
      end

      it "filters by search query" do
        org1 = create(:organization, name: "Harvard University")
        org2 = create(:organization, name: "MIT")

        get admin_organizations_path, params: {search: "Harvard"}

        expect(response.body).to include(org1.name)
        expect(response.body).not_to include(org2.name)
      end

      it "filters by active status" do
        active_org = create(:organization, active: true)
        inactive_org = create(:organization, active: false)

        get admin_organizations_path, params: {status: "active"}

        expect(response.body).to include(active_org.name)
        expect(response.body).not_to include(inactive_org.name)
      end

      it "filters by inactive status" do
        active_org = create(:organization, active: true)
        inactive_org = create(:organization, active: false)

        get admin_organizations_path, params: {status: "inactive"}

        expect(response.body).not_to include(active_org.name)
        expect(response.body).to include(inactive_org.name)
      end
    end

    context "when user is not admin" do
      it "redirects instructor users" do
        sign_in instructor_user
        get admin_organizations_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects student users" do
        sign_in student_user
        get admin_organizations_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects unauthenticated users" do
        get admin_organizations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/organizations/:id" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns success" do
        get admin_organization_path(organization)
        expect(response).to have_http_status(:success)
      end

      it "displays organization details" do
        get admin_organization_path(organization)
        expect(response.body).to include(organization.name)
      end

      it "displays organization statistics" do
        create(:user, organization: organization)
        create(:course, organization: organization)

        get admin_organization_path(organization)

        expect(response.body).to include("Users")
        expect(response.body).to include("Courses")
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        get admin_organization_path(organization)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/organizations/new" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns success" do
        get new_admin_organization_path
        expect(response).to have_http_status(:success)
      end

      it "displays new organization form" do
        get new_admin_organization_path
        expect(response.body).to include("form")
        expect(response.body).to include("Name")
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        get new_admin_organization_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/organizations" do
    let(:valid_attributes) do
      {
        name: "Test University",
        domain: "testuniversity.edu",
        slug: "test-university",
        active: true
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        domain: "invalid-domain",
        slug: "",
        active: true
      }
    end

    context "when user is admin" do
      before { sign_in admin_user }

      context "with valid parameters" do
        it "creates a new organization" do
          expect {
            post admin_organizations_path, params: {organization: valid_attributes}
          }.to change(Organization, :count).by(1)
        end

        it "redirects to the created organization" do
          post admin_organizations_path, params: {organization: valid_attributes}
          expect(response).to redirect_to(admin_organization_path(Organization.last))
        end

        it "sets success notice" do
          post admin_organizations_path, params: {organization: valid_attributes}
          follow_redirect!
          expect(response.body).to include("Organization was successfully created")
        end
      end

      context "with invalid parameters" do
        it "does not create a new organization" do
          expect {
            post admin_organizations_path, params: {organization: invalid_attributes}
          }.not_to change(Organization, :count)
        end

        it "renders the new template" do
          post admin_organizations_path, params: {organization: invalid_attributes}
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        post admin_organizations_path, params: {organization: valid_attributes}
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/organizations/:id/edit" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns success" do
        get edit_admin_organization_path(organization)
        expect(response).to have_http_status(:success)
      end

      it "displays edit organization form" do
        get edit_admin_organization_path(organization)
        expect(response.body).to include("form")
        expect(response.body).to include(organization.name)
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        get edit_admin_organization_path(organization)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/organizations/:id" do
    let(:new_attributes) do
      {
        name: "Updated University",
        domain: "updated.edu"
      }
    end

    context "when user is admin" do
      before { sign_in admin_user }

      context "with valid parameters" do
        it "updates the organization" do
          patch admin_organization_path(organization), params: {organization: new_attributes}
          organization.reload
          expect(organization.name).to eq("Updated University")
          expect(organization.domain).to eq("updated.edu")
        end

        it "redirects to the organization" do
          patch admin_organization_path(organization), params: {organization: new_attributes}
          expect(response).to redirect_to(admin_organization_path(organization))
        end

        it "sets success notice" do
          patch admin_organization_path(organization), params: {organization: new_attributes}
          follow_redirect!
          expect(response.body).to include("Organization was successfully updated")
        end
      end

      context "with invalid parameters" do
        it "renders the edit template" do
          patch admin_organization_path(organization), params: {organization: {name: ""}}
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        patch admin_organization_path(organization), params: {organization: new_attributes}
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /admin/organizations/:id" do
    context "when user is admin" do
      before { sign_in admin_user }

      context "when organization has no users" do
        it "deletes the organization" do
          organization_to_delete = create(:organization)
          expect {
            delete admin_organization_path(organization_to_delete)
          }.to change(Organization, :count).by(-1)
        end

        it "redirects to organizations index" do
          delete admin_organization_path(organization)
          expect(response).to redirect_to(admin_organizations_path)
        end

        it "sets success notice" do
          delete admin_organization_path(organization)
          follow_redirect!
          expect(response.body).to include("Organization was successfully deleted")
        end
      end

      context "when organization has users" do
        before do
          create(:user, organization: organization)
        end

        it "does not delete the organization" do
          expect {
            delete admin_organization_path(organization)
          }.not_to change(Organization, :count)
        end

        it "sets error message" do
          delete admin_organization_path(organization)
          follow_redirect!
          expect(response.body).to include("Cannot delete organization with existing users")
        end
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        delete admin_organization_path(organization)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/organizations/:id/activate" do
    let(:inactive_organization) { create(:organization, active: false) }

    context "when user is admin" do
      before { sign_in admin_user }

      it "activates the organization" do
        patch activate_admin_organization_path(inactive_organization)
        inactive_organization.reload
        expect(inactive_organization.active).to be true
      end

      it "redirects to the organization" do
        patch activate_admin_organization_path(inactive_organization)
        expect(response).to redirect_to(admin_organization_path(inactive_organization))
      end

      it "sets success notice" do
        patch activate_admin_organization_path(inactive_organization)
        follow_redirect!
        expect(response.body).to include("Organization activated successfully")
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        patch activate_admin_organization_path(inactive_organization)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/organizations/:id/deactivate" do
    let(:active_organization) { create(:organization, active: true) }

    context "when user is admin" do
      before { sign_in admin_user }

      it "deactivates the organization" do
        patch deactivate_admin_organization_path(active_organization)
        active_organization.reload
        expect(active_organization.active).to be false
      end

      it "redirects to the organization" do
        patch deactivate_admin_organization_path(active_organization)
        expect(response).to redirect_to(admin_organization_path(active_organization))
      end

      it "sets success notice" do
        patch deactivate_admin_organization_path(active_organization)
        follow_redirect!
        expect(response.body).to include("Organization deactivated successfully")
      end
    end

    context "when user is not admin" do
      it "redirects non-admin users" do
        sign_in instructor_user
        patch deactivate_admin_organization_path(active_organization)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
