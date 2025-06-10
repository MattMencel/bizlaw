require 'rails_helper'

RSpec.describe "CourseInvitations", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/course_invitations/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /join" do
    it "returns http success" do
      get "/course_invitations/join"
      expect(response).to have_http_status(:success)
    end
  end

end
