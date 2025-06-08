# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:login_url) { "/api/login" }
  let(:logout_url) { "/api/logout" }

  describe "POST /api/login" do
    context "with valid credentials" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "password123"
          }
        }
      end

      it "returns 200" do
        expect(response).to have_http_status(200)
      end

      it "returns JWT token in response" do
        expect(response.headers["Authorization"]).to be_present
      end

      it "returns valid JSON body" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]["code"]).to eq(200)
        expect(json_response["data"]["user"]).to be_present
      end
    end

    context "with invalid credentials" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "wrong_password"
          }
        }
      end

      it "returns 401" do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe "DELETE /api/logout" do
    context "when user is signed in" do
      before do
        post login_url, params: {
          user: {
            email: user.email,
            password: "password123"
          }
        }
        @token = response.headers["Authorization"]
        delete logout_url, headers: { "Authorization": @token }
      end

      it "returns 200" do
        expect(response).to have_http_status(200)
      end

      it "blacklists JWT token" do
        get "/api/v1/profile", headers: { "Authorization": @token }
        expect(response).to have_http_status(401)
      end
    end
  end
end
