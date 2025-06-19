# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ContextController, type: :controller do
  include Devise::Test::ControllerHelpers
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:team) { create(:team, course: course) }
  let(:other_case) { create(:case, course: course) }
  let(:other_team) { create(:team, course: course) }

  before do
    sign_in user
    create(:case_team, case: case_obj, team: team)
    create(:case_team, case: other_case, team: other_team)
    create(:team_member, user: user, team: team, role: "member")
    create(:team_member, user: user, team: other_team, role: "member")
  end

  describe "GET #current" do
    before do
      session[:active_case_id] = case_obj.id
      session[:active_team_id] = team.id
    end

    it "returns current context data" do
      get :current, format: :json

      if response.status == 500
        puts "Error response body: #{response.body}"
      end

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "case" => hash_including("id" => case_obj.id, "title" => case_obj.title),
        "team" => hash_including("id" => team.id, "name" => team.name),
        "user_role" => user.primary_role
      )
    end

    context "when user is not signed in" do
      before do
        sign_out user
      end

      it "returns unauthorized" do
        get :current, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH #switch_case" do
    let(:valid_params) { {case_id: other_case.id} }
    let(:invalid_params) { {case_id: "invalid-id"} }

    it "switches to a valid case" do
      patch :switch_case, params: valid_params, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "case" => hash_including("id" => other_case.id),
        "success" => true
      )
      expect(session[:active_case_id]).to eq(other_case.id)
    end

    it "returns error for invalid case" do
      patch :switch_case, params: invalid_params, format: :json

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)

      expect(json_response).to include("error" => "Case not found")
    end

    it "updates session with new team if available" do
      patch :switch_case, params: valid_params, format: :json

      expect(session[:active_case_id]).to eq(other_case.id)
      expect(session[:active_team_id]).to eq(other_team.id)
    end

    context "when user cannot access case" do
      let(:restricted_case) { create(:case) }
      let(:restricted_params) { {case_id: restricted_case.id} }

      it "returns forbidden" do
        patch :switch_case, params: restricted_params, format: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)

        expect(json_response).to include("error" => "Access denied")
      end
    end
  end

  describe "PATCH #switch_team" do
    let(:valid_params) { {team_id: other_team.id} }
    let(:invalid_params) { {team_id: "invalid-id"} }

    it "switches to a valid team" do
      patch :switch_team, params: valid_params, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include(
        "team" => hash_including("id" => other_team.id),
        "success" => true
      )
      expect(session[:active_team_id]).to eq(other_team.id)
    end

    it "returns error for invalid team" do
      patch :switch_team, params: invalid_params, format: :json

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)

      expect(json_response).to include("error" => "Team not found")
    end

    it "updates case session when switching teams" do
      patch :switch_team, params: valid_params, format: :json

      expect(session[:active_team_id]).to eq(other_team.id)
      expect(session[:active_case_id]).to eq(other_case.id)
    end

    context "when user cannot access team" do
      let(:restricted_team) { create(:team) }
      let(:restricted_params) { {team_id: restricted_team.id} }

      it "returns forbidden" do
        patch :switch_team, params: restricted_params, format: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)

        expect(json_response).to include("error" => "Access denied")
      end
    end
  end

  describe "GET #search" do
    let(:search_params) { {q: "test"} }
    let(:empty_params) { {q: ""} }
    let(:short_params) { {q: "a"} }

    before do
      # Set up case and team titles that will match search
      case_obj.update(title: "Test Case Alpha")
      other_case.update(title: "Beta Test Case")
      team.update(name: "Test Team One")
      other_team.update(name: "Team Two Test")
    end

    it "returns search results for valid query" do
      get :search, params: search_params, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include("cases", "teams")
      expect(json_response["cases"]).to be_an(Array)
      expect(json_response["teams"]).to be_an(Array)

      # Check that results contain search term
      case_titles = json_response["cases"].map { |c| c["title"] }
      expect(case_titles).to include("Test Case Alpha", "Beta Test Case")
    end

    it "returns empty results for short query" do
      get :search, params: short_params, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq("cases" => [], "teams" => [])
    end

    it "returns empty results for empty query" do
      get :search, params: empty_params, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq("cases" => [], "teams" => [])
    end

    it "limits results appropriately" do
      # Create many cases to test limit
      10.times do |i|
        test_case = create(:case, title: "Test Case #{i}", course: course)
        test_team = create(:team, course: course)
        create(:case_team, case: test_case, team: test_team)
        create(:team_member, user: user, team: test_team, role: "member")
      end

      get :search, params: search_params, format: :json

      json_response = JSON.parse(response.body)
      expect(json_response["cases"].length).to be <= 5
      expect(json_response["teams"].length).to be <= 5
    end
  end

  describe "GET #available" do
    it "returns available cases and teams" do
      get :available, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response).to include("cases", "teams")
      expect(json_response["cases"]).to be_an(Array)
      expect(json_response["teams"]).to be_an(Array)

      # Check that user's cases are included
      case_ids = json_response["cases"].map { |c| c["id"] }
      expect(case_ids).to include(case_obj.id, other_case.id)
    end

    it "limits results to 10 items" do
      # Create many cases to test limit
      15.times do |i|
        test_case = create(:case, title: "Case #{i}", course: course)
        test_team = create(:team, course: course)
        create(:case_team, case: test_case, team: test_team)
        create(:team_member, user: user, team: test_team, role: "member")
      end

      get :available, format: :json

      json_response = JSON.parse(response.body)
      expect(json_response["cases"].length).to be <= 10
      expect(json_response["teams"].length).to be <= 10
    end
  end

  describe "serialization methods" do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:current_user).and_return(user)
    end

    describe "#serialize_case" do
      it "returns nil for nil case" do
        result = controller_instance.send(:serialize_case, nil)
        expect(result).to be_nil
      end

      it "serializes case with all required fields" do
        result = controller_instance.send(:serialize_case, case_obj)

        expect(result).to include(
          :id, :title, :description, :current_phase, :current_round,
          :total_rounds, :status, :team_status, :user_team,
          :created_at, :updated_at
        )

        expect(result[:id]).to eq(case_obj.id)
        expect(result[:title]).to eq(case_obj.title)
      end
    end

    describe "#serialize_team" do
      it "returns nil for nil team" do
        result = controller_instance.send(:serialize_team, nil)
        expect(result).to be_nil
      end

      it "serializes team with all required fields" do
        result = controller_instance.send(:serialize_team, team)

        expect(result).to include(
          :id, :name, :team_type, :case_id, :case_title,
          :user_role, :member_count, :created_at, :updated_at
        )

        expect(result[:id]).to eq(team.id)
        expect(result[:name]).to eq(team.name)
        expect(result[:case_id]).to eq(case_obj.id)
      end
    end
  end
end
