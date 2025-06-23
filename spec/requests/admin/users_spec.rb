# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:organization1) { create(:organization, name: "University 1") }
  let(:organization2) { create(:organization, name: "University 2") }

  let(:admin) { create(:user, :admin, organization: organization1) }
  let(:instructor) { create(:user, :instructor, organization: organization1) }
  let(:student) { create(:user, :student, organization: organization1) }
  let(:org_admin) { create(:user, :org_admin, organization: organization1) }

  # Users in same organization as org_admin
  let(:same_org_student) { create(:user, :student, organization: organization1) }
  let(:same_org_instructor) { create(:user, :instructor, organization: organization1) }

  # Users in different organization
  let(:other_org_student) { create(:user, :student, organization: organization2) }
  let(:other_org_instructor) { create(:user, :instructor, organization: organization2) }
  let(:other_org_admin) { create(:user, :org_admin, organization: organization2) }

  # User with no organization
  let(:no_org_user) { create(:user, :student, organization: nil) }

  before do
    # Create all test users
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

  describe "GET /admin/users" do
    context "when user is an admin" do
      before { sign_in admin }

      it "returns all users" do
        get admin_users_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(admin.full_name)
        expect(response.body).to include(same_org_student.full_name)
        expect(response.body).to include(other_org_student.full_name)
        expect(response.body).to include(no_org_user.full_name)
      end
    end

    context "when user is an instructor" do
      before { sign_in instructor }

      it "returns all users" do
        get admin_users_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(admin.full_name)
        expect(response.body).to include(same_org_student.full_name)
        expect(response.body).to include(other_org_student.full_name)
        expect(response.body).to include(no_org_user.full_name)
      end
    end

    context "when user is an org_admin" do
      before { sign_in org_admin }

      it "returns only users in the same organization" do
        get admin_users_path

        expect(response).to have_http_status(:ok)

        # Should see users in same organization
        expect(response.body).to include(admin.full_name)
        expect(response.body).to include(instructor.full_name)
        expect(response.body).to include(student.full_name)
        expect(response.body).to include(org_admin.full_name)
        expect(response.body).to include(same_org_student.full_name)
        expect(response.body).to include(same_org_instructor.full_name)

        # Should NOT see users in different organization
        expect(response.body).not_to include(other_org_student.full_name)
        expect(response.body).not_to include(other_org_instructor.full_name)
        expect(response.body).not_to include(other_org_admin.full_name)

        # Should NOT see users with no organization
        expect(response.body).not_to include(no_org_user.full_name)
      end

      it "filters correctly when searching within their organization" do
        get admin_users_path, params: { search: same_org_student.first_name }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(same_org_student.full_name)
        expect(response.body).not_to include(other_org_student.full_name)
      end

      it "shows organization filter but only includes their organization users" do
        get admin_users_path, params: { organization_id: organization1.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(same_org_student.full_name)
        expect(response.body).not_to include(other_org_student.full_name)
      end

      it "does not show users from other organizations even when filtered" do
        get admin_users_path, params: { organization_id: organization2.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(other_org_student.full_name)
        expect(response.body).not_to include(other_org_instructor.full_name)
      end
    end

    context "when org_admin has no organization" do
      let(:org_admin_no_org) { create(:user, :org_admin, organization: nil) }
      before { sign_in org_admin_no_org }

      it "returns no users" do
        get admin_users_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(admin.full_name)
        expect(response.body).not_to include(same_org_student.full_name)
        expect(response.body).not_to include(other_org_student.full_name)
        expect(response.body).not_to include(no_org_user.full_name)
      end
    end

    context "when user is a student" do
      before { sign_in student }

      it "denies access" do
        get admin_users_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get admin_users_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/users/:id" do
    context "when user is org_admin" do
      before { sign_in org_admin }

      it "allows viewing users in same organization" do
        get admin_user_path(same_org_student)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(same_org_student.full_name)
      end

      it "denies viewing users in different organization" do
        expect {
          get admin_user_path(other_org_student)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    context "when user is org_admin" do
      before { sign_in org_admin }

      it "allows updating users in same organization" do
        patch admin_user_path(same_org_student), params: {
          user: { first_name: "Updated Name" }
        }

        expect(response).to have_http_status(:redirect)
        expect(same_org_student.reload.first_name).to eq("Updated Name")
      end

      it "denies updating users in different organization" do
        expect {
          patch admin_user_path(other_org_student), params: {
            user: { first_name: "Updated Name" }
          }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
