# frozen_string_literal: true

require "rails_helper"

RSpec.describe EvidenceVaultController, type: :controller do
  include Devise::Test::ControllerHelpers

  let!(:organization) { create(:organization) }
  let!(:instructor) { create(:user, :instructor, organization: organization) }
  let!(:student1) { create(:user, :student, organization: organization) }
  let!(:student2) { create(:user, :student, organization: organization) }
  let!(:team) { create(:team, name: "Plaintiff Team A") }
  let!(:defendant_team) { create(:team, name: "Defendant Team B") }

  let!(:case_instance) do
    # Create case without validation to avoid the team requirement issue
    case_obj = Case.new(
      title: "Mitchell v. TechFlow Industries",
      case_type: :sexual_harassment,
      description: "Sexual harassment lawsuit involving workplace misconduct allegations",
      reference_number: "CASE-#{rand(1000..9999)}",
      status: :not_started,
      difficulty_level: :intermediate,
      plaintiff_info: {"name" => "Sarah Mitchell", "position" => "Software Engineer"},
      defendant_info: {"name" => "TechFlow Industries", "type" => "Corporation"},
      legal_issues: ["Sexual harassment", "Hostile work environment", "Retaliation"],
      team: team,
      created_by: instructor,
      updated_by: instructor
    )
    case_obj.save!(validate: false)

    # Now create the required case teams manually
    CaseTeam.create!(case: case_obj, team: team, role: :plaintiff)
    CaseTeam.create!(case: case_obj, team: defendant_team, role: :defendant)

    case_obj
  end

  let!(:public_document) do
    create(:document,
      title: "Employee Handbook",
      category: "company_policies",
      access_level: "case_teams",
      tags: ["harassment", "policy"],
      documentable: case_instance)
  end

  let!(:team_restricted_document) do
    create(:document,
      title: "Expert Damages Assessment",
      category: "expert_reports",
      access_level: "team_restricted",
      team_restrictions: {"allowed_teams" => [team.id]},
      tags: ["damages", "economics", "expert"],
      documentable: case_instance)
  end

  let!(:instructor_only_document) do
    create(:document,
      title: "TechFlow Financial Records",
      category: "financial_records",
      access_level: "instructor_only",
      tags: ["financials", "confidential"],
      documentable: case_instance)
  end

  before do
    create(:team_member, user: student1, team: team)
    create(:team_member, user: student2, team: team)
  end

  describe "GET #index" do
    context "when user is not authenticated" do
      it "redirects to login page" do
        get :index, params: {case_id: case_instance.id}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as student team member" do
      before { sign_in student1 }

      it "renders the evidence vault interface" do
        get :index, params: {case_id: case_instance.id}
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "loads documents accessible to the student's team" do
        get :index, params: {case_id: case_instance.id}

        documents = assigns(:documents)
        expect(documents).to include(public_document)
        expect(documents).to include(team_restricted_document)
        expect(documents).not_to include(instructor_only_document)
      end

      it "groups documents by category" do
        get :index, params: {case_id: case_instance.id}

        categories = assigns(:document_categories)
        expect(categories).to include("company_policies")
        expect(categories).to include("expert_reports")
        expect(categories).not_to include("financial_records")
      end

      it "includes document metadata for frontend" do
        get :index, params: {case_id: case_instance.id}

        expect(assigns(:case)).to eq(case_instance)
        expect(assigns(:current_team)).to eq(team)
        expect(assigns(:total_documents)).to eq(2) # Excludes instructor-only
      end
    end

    context "when authenticated as instructor" do
      before { sign_in instructor }

      it "loads all documents including instructor-only" do
        get :index, params: {case_id: case_instance.id}

        documents = assigns(:documents)
        expect(documents).to include(public_document)
        expect(documents).to include(team_restricted_document)
        expect(documents).to include(instructor_only_document)
      end
    end

    context "when student is not member of case team" do
      let(:other_student) { create(:user, :student) }

      before { sign_in other_student }

      it "returns forbidden status" do
        get :index, params: {case_id: case_instance.id}
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #search" do
    before { sign_in student1 }

    it "searches documents by query term" do
      get :search, params: {
        case_id: case_instance.id,
        q: "harassment",
        format: :json
      }

      expect(response).to have_http_status(:success)

      results = JSON.parse(response.body)
      expect(results["documents"]).to be_an(Array)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Employee Handbook")
    end

    it "filters by category" do
      get :search, params: {
        case_id: case_instance.id,
        category: "expert_reports",
        format: :json
      }

      expect(response).to have_http_status(:success)

      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Expert Damages Assessment")
    end

    it "filters by tags" do
      get :search, params: {
        case_id: case_instance.id,
        tags: ["economics"],
        format: :json
      }

      expect(response).to have_http_status(:success)

      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Expert Damages Assessment")
    end

    it "respects access control in search results" do
      get :search, params: {
        case_id: case_instance.id,
        q: "financial",
        format: :json
      }

      results = JSON.parse(response.body)
      expect(results["documents"]).to be_empty # Student can't see instructor-only docs
    end

    it "includes search metadata" do
      get :search, params: {
        case_id: case_instance.id,
        q: "harassment",
        format: :json
      }

      results = JSON.parse(response.body)
      expect(results["total_results"]).to eq(1)
      expect(results["search_query"]).to eq("harassment")
      expect(results["available_categories"]).to be_an(Array)
      expect(results["available_tags"]).to be_an(Array)
    end
  end

  describe "GET #show" do
    before { sign_in student1 }

    it "returns document details for preview" do
      get :show, params: {
        case_id: case_instance.id,
        id: public_document.id,
        format: :json
      }

      expect(response).to have_http_status(:success)

      document = JSON.parse(response.body)
      expect(document["title"]).to eq("Employee Handbook")
      expect(document["category"]).to eq("company_policies")
      expect(document["tags"]).to include("harassment", "policy")
    end

    it "includes annotations if present" do
      public_document.update!(
        annotations: [
          {
            id: SecureRandom.uuid,
            user_id: student2.id,
            user_name: "Bob Smith",
            team_id: team.id,
            content: "Important policy section",
            page: 1,
            created_at: 1.hour.ago
          }
        ]
      )

      get :show, params: {
        case_id: case_instance.id,
        id: public_document.id,
        format: :json
      }

      document = JSON.parse(response.body)
      expect(document["annotations"]).to be_an(Array)
      expect(document["annotations"].first["content"]).to eq("Important policy section")
    end

    it "denies access to restricted documents" do
      get :show, params: {
        case_id: case_instance.id,
        id: instructor_only_document.id,
        format: :json
      }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST #annotate" do
    before { sign_in student1 }

    it "adds annotation to document" do
      post :annotate, params: {
        case_id: case_instance.id,
        id: public_document.id,
        annotation: {
          content: "This section is relevant to our case",
          page: 2
        },
        format: :json
      }

      expect(response).to have_http_status(:success)

      public_document.reload
      annotations = public_document.annotations
      expect(annotations).to be_an(Array)
      expect(annotations.last["content"]).to eq("This section is relevant to our case")
      expect(annotations.last["user_id"]).to eq(student1.id)
      expect(annotations.last["team_id"]).to eq(team.id)
    end

    it "validates annotation content" do
      post :annotate, params: {
        case_id: case_instance.id,
        id: public_document.id,
        annotation: {
          content: "", # Empty content
          page: 2
        },
        format: :json
      }

      expect(response).to have_http_status(:unprocessable_entity)

      error = JSON.parse(response.body)
      expect(error["errors"]).to include("Content cannot be blank")
    end

    it "denies annotation on restricted documents" do
      post :annotate, params: {
        case_id: case_instance.id,
        id: instructor_only_document.id,
        annotation: {
          content: "Trying to annotate restricted doc",
          page: 1
        },
        format: :json
      }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PUT #update_tags" do
    before { sign_in student1 }

    it "updates document tags" do
      put :update_tags, params: {
        case_id: case_instance.id,
        id: public_document.id,
        tags: ["harassment", "policy", "new-tag"],
        format: :json
      }

      expect(response).to have_http_status(:success)

      public_document.reload
      expect(public_document.tags).to include("new-tag")
    end

    it "validates tag format" do
      put :update_tags, params: {
        case_id: case_instance.id,
        id: public_document.id,
        tags: ["valid-tag", "", "  "], # Invalid tags
        format: :json
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST #create_bundle" do
    before { sign_in student1 }

    it "creates evidence bundle with selected documents" do
      post :create_bundle, params: {
        case_id: case_instance.id,
        bundle: {
          name: "Harassment Evidence Package",
          document_ids: [public_document.id, team_restricted_document.id]
        },
        format: :json
      }

      expect(response).to have_http_status(:created)

      bundle = JSON.parse(response.body)
      expect(bundle["name"]).to eq("Harassment Evidence Package")
      expect(bundle["document_count"]).to eq(2)
    end

    it "validates bundle has at least one document" do
      post :create_bundle, params: {
        case_id: case_instance.id,
        bundle: {
          name: "Empty Bundle",
          document_ids: []
        },
        format: :json
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "performance and security" do
    before { sign_in student1 }

    it "efficiently loads large document sets" do
      # Create many documents
      create_list(:document, 50, documentable: case_instance, access_level: "case_teams")

      expect {
        get :index, params: {case_id: case_instance.id}
      }.not_to exceed_query_limit(10)
    end

    it "sanitizes search input to prevent injection" do
      malicious_query = "'; DROP TABLE documents; --"

      get :search, params: {
        case_id: case_instance.id,
        q: malicious_query,
        format: :json
      }

      expect(response).to have_http_status(:success)
      # Verify database is still intact
      expect(Document.count).to be > 0
    end
  end
end
