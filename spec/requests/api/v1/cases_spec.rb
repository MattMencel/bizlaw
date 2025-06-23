# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Cases", type: :request do
  let(:user) { create(:user) }
  let(:case_type) { create(:case_type) }
  let(:team) { create(:team, owner: user) }
  let(:plaintiff_team) { create(:team) }
  let(:defendant_team) { create(:team) }
  let(:kase) { create(:case, created_by: user, updated_by: user, team: team, case_type: case_type) }

  before { sign_in user }

  describe "GET /api/v1/cases" do
    before do
      kase
      create(:case) # Another case not owned by user
    end

    it "returns a list of cases accessible by the user" do
      get "/api/v1/cases"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"].length).to eq(1)
      expect(json["data"].first["attributes"]["title"]).to eq(kase.title)
    end

    context "with search query" do
      let!(:searchable_case) { create(:case, title: "Contract Law Case", created_by: user, updated_by: user) }

      it "returns cases matching the search query" do
        get "/api/v1/cases", params: {query: "Contract"}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
        expect(json["data"].first["attributes"]["title"]).to eq("Contract Law Case")
      end
    end

    context "with filters" do
      let!(:advanced_case) { create(:case, difficulty_level: :advanced, created_by: user, updated_by: user) }
      let!(:in_progress_case) { create(:case, status: :in_progress, created_by: user, updated_by: user) }

      it "filters by difficulty level" do
        get "/api/v1/cases", params: {difficulty_level: "advanced"}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
        expect(json["data"].first["id"]).to eq(advanced_case.id)
      end

      it "filters by status" do
        get "/api/v1/cases", params: {status: "in_progress"}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
        expect(json["data"].first["id"]).to eq(in_progress_case.id)
      end
    end

    context "with pagination" do
      before { create_list(:case, 5, created_by: user, updated_by: user) }

      it "returns paginated results" do
        get "/api/v1/cases", params: {page: 1, per_page: 2}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(2)
        expect(json["meta"]["total_pages"]).to eq(3)
        expect(json["meta"]["total_count"]).to eq(6)
      end
    end
  end

  describe "GET /api/v1/cases/:id" do
    it "returns the requested case" do
      get "/api/v1/cases/#{kase.id}"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["title"]).to eq(kase.title)
    end

    it "returns not found for non-existent case" do
      get "/api/v1/cases/non-existent-id"
      expect(response).to have_http_status(:not_found)
    end

    it "includes related resources in response" do
      get "/api/v1/cases/#{kase.id}"

      json = JSON.parse(response.body)
      expect(json["included"]).to include(
        a_hash_including("type" => "team", "id" => team.id.to_s)
      )
      expect(json["included"]).to include(
        a_hash_including("type" => "case_type", "id" => case_type.id.to_s)
      )
    end
  end

  describe "POST /api/v1/cases" do
    let(:valid_attributes) do
      {
        case: {
          title: "Test Case",
          description: "Test description",
          reference_number: "CASE-001",
          status: "not_started",
          difficulty_level: "beginner",
          case_type: "contract_dispute",
          team_id: team.id,
          case_type_id: case_type.id,
          plaintiff_info: {name: "Plaintiff"},
          defendant_info: {name: "Defendant"},
          legal_issues: ["Contract breach"],
          case_teams_attributes: [
            {team_id: plaintiff_team.id, role: "plaintiff"},
            {team_id: defendant_team.id, role: "defendant"}
          ]
        }
      }
    end

    it "creates a new case" do
      expect {
        post "/api/v1/cases", params: valid_attributes
      }.to change(Case, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["title"]).to eq("Test Case")
    end

    it "returns validation errors for invalid attributes" do
      post "/api/v1/cases", params: {case: {title: ""}}
      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Title can't be blank")
    end
  end

  describe "PATCH /api/v1/cases/:id" do
    let(:update_attributes) do
      {
        case: {
          title: "Updated Case",
          description: "Updated description"
        }
      }
    end

    it "updates the case" do
      patch "/api/v1/cases/#{kase.id}", params: update_attributes
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["title"]).to eq("Updated Case")
    end

    it "returns forbidden for unauthorized user" do
      other_case = create(:case)
      patch "/api/v1/cases/#{other_case.id}", params: update_attributes
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/cases/:id" do
    context "when case can be deleted" do
      let(:deletable_case) { create(:case, status: :not_started, created_by: user, case_type: "sexual_harassment") }

      it "deletes the case" do
        delete "/api/v1/cases/#{deletable_case.id}"
        expect(response).to have_http_status(:no_content)
        expect(Case.find_by(id: deletable_case.id)).to be_nil
      end
    end

    context "when case cannot be deleted due to status" do
      let(:in_progress_case) { create(:case, status: :in_progress, created_by: user, case_type: "sexual_harassment") }

      it "returns unprocessable entity with error message" do
        delete "/api/v1/cases/#{in_progress_case.id}"
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Case can only be deleted when in 'Not Started' status")
      end

      it "does not delete the case" do
        in_progress_case # Ensure case is created before counting
        expect {
          delete "/api/v1/cases/#{in_progress_case.id}"
        }.not_to change(Case, :count)
      end
    end

    context "when case cannot be deleted due to student team members" do
      let(:student) { create(:user, :student) }
      let(:instructor) { create(:user, :instructor) }
      let(:test_course) { create(:course, instructor: instructor) }
      let(:student_team) { create(:team, course: test_course, owner: student) }
      let(:case_with_students) { create(:case, status: :not_started, created_by: user, course: test_course, case_type: "sexual_harassment") }

      before do
        create(:team_member, team: student_team, user: student, role: :member)
        create(:case_team, case: case_with_students, team: student_team, role: :plaintiff)
      end

      it "returns unprocessable entity with error message" do
        delete "/api/v1/cases/#{case_with_students.id}"
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Cannot delete case with teams that have student members")
      end

      it "does not delete the case" do
        case_with_students # Ensure case is created before counting
        expect {
          delete "/api/v1/cases/#{case_with_students.id}"
        }.not_to change(Case, :count)
      end
    end

    it "returns forbidden for unauthorized user" do
      other_case = create(:case, case_type: "sexual_harassment")
      delete "/api/v1/cases/#{other_case.id}"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
