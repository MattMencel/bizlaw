# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Registrations", type: :request do
  let(:signup_url) { "/api/signup" }
  let(:valid_attributes) do
    {
      user: {
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "John",
        last_name: "Doe",
        role: "student"
      }
    }
  end

  describe "POST /api/signup" do
    context "with valid parameters" do
      before do
        post signup_url, params: valid_attributes
      end

      it "returns 200" do
        expect(response).to have_http_status(200)
      end

      it "creates a new user" do
        expect(User.count).to eq(1)
      end

      it "returns JWT token" do
        expect(response.headers["Authorization"]).to be_present
      end

      it "returns valid JSON body" do
        json_response = JSON.parse(response.body)
        expect(json_response["status"]["code"]).to eq(200)
        expect(json_response["data"]["user"]["email"]).to eq("test@example.com")
      end
    end

    context "with invalid parameters" do
      before do
        post signup_url, params: {
          user: {
            email: "invalid_email",
            password: "short",
            first_name: "",
            role: "invalid_role"
          }
        }
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
