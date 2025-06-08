# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Profiles", type: :request do
  let(:user) { create(:user) }
  let(:profile_url) { "/api/v1/profile" }
  let(:login_url) { "/api/login" }

  describe "GET /api/v1/profile" do
    context "when user is authenticated" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "password"
          }
        }
        @token = response.headers["Authorization"]
        get profile_url, headers: { "Authorization": @token }
      end

      it "returns 200" do
        expect(response).to have_http_status(200)
      end

      it "returns user profile data" do
        json_response = JSON.parse(response.body)
        expect(json_response["data"]["email"]).to eq(user.email)
        expect(json_response["data"]["full_name"]).to eq(user.full_name)
      end
    end

    context "when user is not authenticated" do
      before { get profile_url }

      it "returns 401" do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "PATCH /api/v1/profile" do
    let(:valid_attributes) do
      {
        user: {
          first_name: "Updated",
          last_name: "Name"
        }
      }
    end

    context "when user is authenticated" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "password"
          }
        }
        @token = response.headers["Authorization"]
        patch profile_url,
              params: valid_attributes,
              headers: { "Authorization": @token }
      end

      it "returns 200" do
        expect(response).to have_http_status(200)
      end

      it "updates user profile" do
        user.reload
        expect(user.first_name).to eq("Updated")
        expect(user.last_name).to eq("Name")
      end

      it "returns updated profile data" do
        json_response = JSON.parse(response.body)
        expect(json_response["data"]["first_name"]).to eq("Updated")
        expect(json_response["data"]["last_name"]).to eq("Name")
      end
    end

    context "with invalid attributes" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "password"
          }
        }
        @token = response.headers["Authorization"]
        patch profile_url,
              params: { user: { email: "invalid_email" } },
              headers: { "Authorization": @token }
      end

      it "returns 422" do
        expect(response).to have_http_status(422)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]["errors"]).to be_present
      end
    end
  end
end
