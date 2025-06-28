require "rails_helper"

RSpec.describe "Api::V1::EvidenceReleases", type: :request do
  let(:organization) { create(:organization) }
  let(:course) { create(:course, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:simulation) { create(:simulation, case: case_obj, status: "active", current_round: 1, total_rounds: 4) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }
  let(:team) { create(:team) }
  let(:document) { create(:document, documentable: case_obj, document_type: "assignment") }

  before do
    create(:case_team, case: case_obj, team: team)
    create(:team_member, team: team, user: student)
  end

  describe "GET /api/v1/cases/:case_id/evidence_releases" do
    let!(:auto_release_round_1) { create(:evidence_release, simulation: simulation, document: document, release_round: 1, auto_release: true) }
    let!(:auto_release_round_2) { create(:evidence_release, :round_2, simulation: simulation, document: document, auto_release: true) }
    let!(:team_request) { create(:evidence_release, :team_requested, simulation: simulation, document: document, requesting_team: team) }
    let!(:other_team_request) { create(:evidence_release, :team_requested, simulation: simulation, document: document) }

    context "as an instructor" do
      before { sign_in instructor }

      it "returns all evidence releases" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to have(4).items
        expect(json_response["meta"]["total_releases"]).to eq(4)
        expect(json_response["meta"]["current_round"]).to eq(1)
        expect(json_response["meta"]["evidence_types"]).to include("witness_statement", "expert_report")
      end

      it "includes comprehensive release information" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"

        json_response = JSON.parse(response.body)
        release_data = json_response["data"].first

        expect(release_data).to include(
          "id",
          "document_title",
          "evidence_type",
          "release_round",
          "scheduled_release_at",
          "released_at",
          "status",
          "team_requested",
          "requesting_team",
          "impact_description",
          "auto_release",
          "can_access"
        )
      end

      it "orders releases by round and scheduled time" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"

        json_response = JSON.parse(response.body)
        rounds = json_response["data"].map { |r| r["release_round"] }
        expect(rounds).to eq(rounds.sort)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "returns only auto releases and own team requests" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to have(3).items # 2 auto + 1 own team request

        requesting_teams = json_response["data"].map { |r| r["requesting_team"] }.compact
        expect(requesting_teams).to all(eq(team.name))
      end

      it "filters out other teams' requests" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"

        json_response = JSON.parse(response.body)
        other_team_requests = json_response["data"].select { |r| r["id"] == other_team_request.id }
        expect(other_team_requests).to be_empty
      end
    end

    context "without case access" do
      let(:other_user) { create(:user, :student, organization: organization) }

      before { sign_in other_user }

      it "returns forbidden" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "unauthenticated" do
      it "returns unauthorized" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/cases/:case_id/evidence_releases/:id" do
    let(:evidence_release) { create(:evidence_release, simulation: simulation, document: document) }

    context "as an instructor" do
      before { sign_in instructor }

      it "returns evidence release details" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["id"]).to eq(evidence_release.id)
        expect(json_response["data"]["evidence_type"]).to eq(evidence_release.evidence_type)
        expect(json_response["data"]["document_title"]).to eq(document.title)
      end

      it "includes detailed information" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}"

        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to include(
          "release_conditions",
          "document_url",
          "simulation_events"
        )
      end
    end

    context "as a student with access" do
      before { sign_in student }

      let(:team_evidence_release) { create(:evidence_release, :team_requested, simulation: simulation, document: document, requesting_team: team) }

      it "returns accessible evidence release" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/#{team_evidence_release.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["data"]["id"]).to eq(team_evidence_release.id)
      end
    end

    context "as a student without access" do
      before { sign_in student }

      let(:other_team_evidence_release) { create(:evidence_release, :team_requested, simulation: simulation, document: document) }

      it "returns not found" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/#{other_team_evidence_release.id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/cases/:case_id/evidence_releases" do
    before { sign_in student }

    let(:valid_params) do
      {
        evidence_release: {
          document_id: document.id,
          evidence_type: "financial_document",
          justification: "Need financial records to calculate damages"
        }
      }
    end

    context "with valid parameters" do
      it "creates a team evidence request" do
        expect {
          post "/api/v1/cases/#{case_obj.id}/evidence_releases", params: valid_params
        }.to change(EvidenceRelease, :count).by(1)

        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        evidence_release = EvidenceRelease.find(json_response["data"]["id"])

        expect(evidence_release.team_requested?).to be true
        expect(evidence_release.requesting_team).to eq(team)
        expect(evidence_release.evidence_type).to eq("financial_document")
        expect(evidence_release.release_conditions["request_justification"]).to eq("Need financial records to calculate damages")
      end

      it "sets the current round" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases", params: valid_params

        json_response = JSON.parse(response.body)
        evidence_release = EvidenceRelease.find(json_response["data"]["id"])
        expect(evidence_release.release_round).to eq(simulation.current_round)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          evidence_release: {
            document_id: nil,
            evidence_type: "invalid_type",
            justification: ""
          }
        }
      end

      it "returns validation errors" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to be_present
      end
    end

    context "as instructor" do
      before { sign_in instructor }

      it "returns forbidden" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases", params: valid_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when team already has pending request for document" do
      before do
        create(:evidence_release, :team_requested,
          simulation: simulation,
          document: document,
          requesting_team: team,
          released_at: nil)
      end

      it "returns conflict error" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases", params: valid_params

        expect(response).to have_http_status(:conflict)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("already has a pending request")
      end
    end
  end

  describe "PUT /api/v1/cases/:case_id/evidence_releases/:id/approve" do
    let(:evidence_release) { create(:evidence_release, :team_requested, simulation: simulation, document: document, requesting_team: team) }

    context "as an instructor" do
      before { sign_in instructor }

      it "approves the evidence release request" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/approve"

        expect(response).to have_http_status(:ok)

        evidence_release.reload
        expect(evidence_release.release_conditions["approved_by"]).to eq(instructor.email)
        expect(evidence_release.release_conditions["approved_at"]).to be_present
      end

      it "automatically releases approved evidence" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/approve"

        evidence_release.reload
        expect(evidence_release.released_at).to be_present
        expect(evidence_release.document.reload.access_level).to eq("case_teams")
      end

      it "creates a simulation event" do
        expect {
          put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/approve"
        }.to change { simulation.simulation_events.count }.by(1)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "returns forbidden" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/approve"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "for already released evidence" do
      before { sign_in instructor }

      let(:released_evidence) { create(:evidence_release, :released, :team_requested, simulation: simulation, document: document) }

      it "returns unprocessable entity" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{released_evidence.id}/approve"
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /api/v1/cases/:case_id/evidence_releases/:id/deny" do
    let(:evidence_release) { create(:evidence_release, :team_requested, simulation: simulation, document: document, requesting_team: team) }

    context "as an instructor" do
      before { sign_in instructor }

      let(:deny_params) do
        {
          denial_reason: "Request does not meet case requirements"
        }
      end

      it "denies the evidence release request" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/deny", params: deny_params

        expect(response).to have_http_status(:ok)

        evidence_release.reload
        expect(evidence_release.release_conditions["denied_by"]).to eq(instructor.email)
        expect(evidence_release.release_conditions["denied_at"]).to be_present
        expect(evidence_release.release_conditions["denial_reason"]).to eq("Request does not meet case requirements")
      end

      it "does not release the evidence" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/deny", params: deny_params

        evidence_release.reload
        expect(evidence_release.released_at).to be_nil
        expect(evidence_release.document.reload.access_level).not_to eq("case_teams")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "returns forbidden" do
        put "/api/v1/cases/#{case_obj.id}/evidence_releases/#{evidence_release.id}/deny",
          params: {denial_reason: "test"}
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v1/cases/:case_id/evidence_releases/schedule" do
    context "as an instructor" do
      before { sign_in instructor }

      let!(:scheduled_releases) do
        [
          create(:evidence_release, simulation: simulation, document: document, release_round: 1),
          create(:evidence_release, :round_2, simulation: simulation, document: document),
          create(:evidence_release, :round_3, simulation: simulation, document: document)
        ]
      end

      it "returns scheduling overview" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule"

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["rounds"]).to have(4).items # total_rounds
        expect(json_response["data"]["total_releases"]).to eq(3)
        expect(json_response["meta"]["simulation_dates"]).to be_present
      end

      it "groups releases by round" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule"

        json_response = JSON.parse(response.body)
        round_1_releases = json_response["data"]["rounds"][0]["releases"]
        expect(round_1_releases).to have(1).item
      end
    end

    context "as a student" do
      before { sign_in student }

      it "returns forbidden" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule"
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/cases/:case_id/evidence_releases/schedule_automatic" do
    context "as an instructor" do
      before { sign_in instructor }

      let(:schedule_params) do
        {
          releases: [
            {
              document_id: document.id,
              evidence_type: "expert_report",
              release_round: 2,
              impact_description: "Expert analysis on liability"
            },
            {
              document_id: document.id,
              evidence_type: "financial_document",
              release_round: 3,
              impact_description: "Company financial records"
            }
          ]
        }
      end

      it "schedules multiple automatic releases" do
        expect {
          post "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule_automatic", params: schedule_params
        }.to change(EvidenceRelease, :count).by(2)

        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["scheduled_releases"]).to have(2).items

        releases = EvidenceRelease.where(simulation: simulation).order(:release_round)
        expect(releases.map(&:evidence_type)).to include("expert_report", "financial_document")
        expect(releases.map(&:auto_release)).to all(be true)
      end

      it "calculates appropriate release dates" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule_automatic", params: schedule_params

        round_2_release = EvidenceRelease.find_by(release_round: 2)
        round_3_release = EvidenceRelease.find_by(release_round: 3)

        expect(round_2_release.scheduled_release_at).to be > round_2_release.simulation.start_date + 1.week
        expect(round_3_release.scheduled_release_at).to be > round_2_release.scheduled_release_at
      end
    end

    context "as a student" do
      before { sign_in student }

      it "returns forbidden" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule_automatic",
          params: {releases: []}
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with invalid parameters" do
      before { sign_in instructor }

      let(:invalid_params) do
        {
          releases: [
            {
              document_id: nil,
              evidence_type: "invalid_type",
              release_round: 0
            }
          ]
        }
      end

      it "returns validation errors" do
        post "/api/v1/cases/#{case_obj.id}/evidence_releases/schedule_automatic", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to be_present
      end
    end
  end

  describe "performance" do
    context "with large datasets" do
      before do
        sign_in instructor
        create_list(:evidence_release, 50, simulation: simulation, document: document)
      end

      it "efficiently loads evidence releases with associations" do
        expect {
          get "/api/v1/cases/#{case_obj.id}/evidence_releases"
        }.not_to exceed_query_limit(10) # Prevent N+1 queries
      end
    end
  end

  describe "error handling" do
    before { sign_in instructor }

    context "with invalid case ID" do
      it "returns not found" do
        get "/api/v1/cases/invalid-id/evidence_releases"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with inactive simulation" do
      before { simulation.update!(status: "completed") }

      it "returns appropriate error" do
        get "/api/v1/cases/#{case_obj.id}/evidence_releases"
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
