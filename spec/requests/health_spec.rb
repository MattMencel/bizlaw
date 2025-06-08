require 'rails_helper'

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "returns a successful response" do
      get "/health"
      expect(response).to have_http_status(:success)
    end

    it "returns the correct JSON structure" do
      get "/health"
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "status" => "ok",
        "timestamp" => be_present
      )
    end
  end
end
