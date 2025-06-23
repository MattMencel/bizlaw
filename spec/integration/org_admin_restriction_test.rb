# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OrgAdmin User Restriction Integration Test", type: :request do
  let!(:org1) { create(:organization, name: "University A") }
  let!(:org2) { create(:organization, name: "University B") }

  let!(:org_admin) { create(:user, :org_admin, organization: org1, first_name: "OrgAdmin", last_name: "User") }
  let!(:org1_student) { create(:user, :student, organization: org1, first_name: "Org1", last_name: "Student") }
  let!(:org2_student) { create(:user, :student, organization: org2, first_name: "Org2", last_name: "Student") }

  before { sign_in org_admin }

  describe "Policy Scope Test" do
    it "orgAdmin can only see users in their organization via policy scope" do
      visible_users = UserPolicy::Scope.new(org_admin, User).resolve

      expect(visible_users).to include(org_admin, org1_student)
      expect(visible_users).not_to include(org2_student)

      # Verify counts
      expect(visible_users.count).to eq(2)
      expect(User.count).to be > 2  # Should be more total users
    end
  end

  describe "Admin Users Page Integration" do
    it "orgAdmin sees only same organization users on admin users page" do
      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("OrgAdmin User")
      expect(response.body).to include("Org1 Student")
      expect(response.body).not_to include("Org2 Student")
    end
  end

  describe "Individual User Access" do
    it "orgAdmin can access same organization users" do
      get admin_user_path(org1_student)
      expect(response).to have_http_status(:ok)
    end

    it "orgAdmin cannot access different organization users" do
      expect {
        get admin_user_path(org2_student)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
