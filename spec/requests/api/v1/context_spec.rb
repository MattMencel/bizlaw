# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Context", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :student, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:second_case) { create(:case, course: course) }
  let(:team) { create(:team) }
  let(:second_team) { create(:team) }

  before do
    # Set up case-team relationships
    create(:case_team, case: case_obj, team: team)
    create(:case_team, case: second_case, team: second_team)

    # Add user to teams
    user.teams << [team, second_team]

    sign_in user
  end

  describe "GET /api/v1/context/current" do
    context "when user has no active case in session" do
      it "returns the first available case" do
        get "/api/v1/context/current"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["case"]).to be_present
        expect(json_response["case"]["id"]).to eq(case_obj.id)
      end
    end

    context "when user has active case in session" do
      before do
        # Set active case in session
        patch "/api/v1/context/switch_case", params: {case_id: second_case.id}
      end

      it "returns the active case from session" do
        get "/api/v1/context/current"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["case"]["id"]).to eq(second_case.id)
      end
    end

    context "when user has no accessible cases" do
      let(:user_without_cases) { create(:user, :student, organization: organization) }

      before do
        sign_in user_without_cases
      end

      it "returns no case information" do
        get "/api/v1/context/current"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["case"]).to be_nil
        expect(json_response["team"]).to be_nil
      end
    end
  end

  describe "PATCH /api/v1/context/switch_case" do
    context "with valid case ID" do
      it "switches to the specified case" do
        patch "/api/v1/context/switch_case", params: {case_id: second_case.id}

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["case"]["id"]).to eq(second_case.id)
        expect(json_response["success"]).to be true

        # Verify session was updated
        get "/api/v1/context/current"
        json_response = JSON.parse(response.body)
        expect(json_response["case"]["id"]).to eq(second_case.id)
      end
    end

    context "with case user cannot access" do
      let(:other_course) { create(:course, organization: organization) }
      let(:inaccessible_case) { create(:case, course: other_course) }

      it "returns an error" do
        patch "/api/v1/context/switch_case", params: {case_id: inaccessible_case.id}

        expect(response).to have_http_status(:forbidden)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to be_present
      end
    end

    context "with invalid case ID" do
      it "returns not found error" do
        patch "/api/v1/context/switch_case", params: {case_id: "invalid-id"}

        expect(response).to have_http_status(:not_found)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to be_present
      end
    end
  end

  describe "PATCH /api/v1/context/switch_team" do
    context "with valid team ID in current case" do
      before do
        # Set active case first
        patch "/api/v1/context/switch_case", params: {case_id: case_obj.id}
      end

      it "switches to the specified team" do
        patch "/api/v1/context/switch_team", params: {team_id: team.id}

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["team"]["id"]).to eq(team.id)
        expect(json_response["success"]).to be true
      end
    end

    context "with team from different case" do
      before do
        # Set active case to first case
        patch "/api/v1/context/switch_case", params: {case_id: case_obj.id}
      end

      it "returns an error" do
        patch "/api/v1/context/switch_team", params: {team_id: second_team.id}

        expect(response).to have_http_status(:forbidden)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to be_present
      end
    end

    context "when user has no active case" do
      it "returns an error" do
        patch "/api/v1/context/switch_team", params: {team_id: team.id}

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to be_present
      end
    end
  end

  describe "GET /api/v1/context/available" do
    it "returns available cases and teams for switching" do
      get "/api/v1/context/available"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response["cases"]).to be_present
      expect(json_response["cases"].length).to eq(2)

      case_ids = json_response["cases"].map { |c| c["id"] }
      expect(case_ids).to include(case_obj.id, second_case.id)
    end

    context "when user has an active case" do
      before do
        patch "/api/v1/context/switch_case", params: {case_id: case_obj.id}
      end

      it "returns teams available in the current case" do
        get "/api/v1/context/available"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["teams"]).to be_present

        # Should only show teams from current case
        team_ids = json_response["teams"].map { |t| t["id"] }
        expect(team_ids).to include(team.id)
        expect(team_ids).not_to include(second_team.id)
      end
    end
  end

  describe "GET /api/v1/context/search" do
    context "with valid search query" do
      it "returns matching cases and teams" do
        get "/api/v1/context/search", params: {q: case_obj.title[0..4]}

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["cases"]).to be_present

        matching_case = json_response["cases"].find { |c| c["id"] == case_obj.id }
        expect(matching_case).to be_present
      end
    end

    context "with query too short" do
      it "returns an error" do
        get "/api/v1/context/search", params: {q: "a"}

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to be_present
      end
    end

    context "with no matches" do
      it "returns empty results" do
        get "/api/v1/context/search", params: {q: "nonexistent"}

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["cases"]).to be_empty
        expect(json_response["teams"]).to be_empty
      end
    end
  end

  describe "Context resolution for navigation URLs" do
    context "when user has active case" do
      before do
        patch "/api/v1/context/switch_case", params: {case_id: case_obj.id}
      end

      it "allows navigation helper to resolve current case" do
        get "/api/v1/context/current"

        json_response = JSON.parse(response.body)
        current_case_id = json_response["case"]["id"]

        # This demonstrates that the API provides the case ID that
        # the navigation helper can use to resolve "current" URLs
        expect(current_case_id).to eq(case_obj.id)

        # The navigation helper would use this to generate URLs like:
        # /cases/#{current_case_id}/evidence_vault instead of /cases/current/evidence_vault
      end
    end

    context "when user has no active case" do
      let(:user_without_cases) { create(:user, :student, organization: organization) }

      before do
        sign_in user_without_cases
      end

      it "returns nil case for safe fallback URL generation" do
        get "/api/v1/context/current"

        json_response = JSON.parse(response.body)
        expect(json_response["case"]).to be_nil

        # This allows the navigation helper to generate safe fallback URLs
        # like "#" instead of trying to use a non-existent case ID
      end
    end
  end

  describe "Session persistence" do
    it "maintains context across requests" do
      # Switch to a specific case
      patch "/api/v1/context/switch_case", params: {case_id: second_case.id}
      expect(response).to have_http_status(:ok)

      # Make subsequent requests to verify session persistence
      get "/api/v1/context/current"
      json_response = JSON.parse(response.body)
      expect(json_response["case"]["id"]).to eq(second_case.id)

      # Switch team within that case
      patch "/api/v1/context/switch_team", params: {team_id: second_team.id}
      expect(response).to have_http_status(:ok)

      # Verify both case and team are maintained
      get "/api/v1/context/current"
      json_response = JSON.parse(response.body)
      expect(json_response["case"]["id"]).to eq(second_case.id)
      expect(json_response["team"]["id"]).to eq(second_team.id)
    end
  end

  describe "Error handling" do
    context "when not authenticated" do
      before do
        sign_out user
      end

      it "returns unauthorized error" do
        get "/api/v1/context/current"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when switching to deleted case" do
      before do
        case_obj.destroy
      end

      it "handles soft-deleted case gracefully" do
        patch "/api/v1/context/switch_case", params: {case_id: case_obj.id}
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def sign_in(user)
    post "/api/v1/login", params: {
      email: user.email,
      password: user.password
    }
  end

  def sign_out(user)
    delete "/api/v1/logout"
  end
end
