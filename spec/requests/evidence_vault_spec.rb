# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Evidence Vault", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, :student, organization: organization, first_name: "Alice", last_name: "Johnson") }
  let(:student2) { create(:user, :student, organization: organization, first_name: "Bob", last_name: "Smith") }
  let(:team) { create(:team, name: "Plaintiff Team A") }
  let(:case_instance) { create(:case, title: "Mitchell v. TechFlow Industries", case_type: :sexual_harassment) }

  before do
    create(:team_member, user: student1, team: team)
    create(:team_member, user: student2, team: team)
    create(:case_team, case: case_instance, team: team, role: :plaintiff)
  end

  describe "GET /cases/:id/evidence_vault" do
    context "when not authenticated" do
      it "redirects to login" do
        get case_evidence_vault_index_path(case_instance)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as team member" do
      before { sign_in student1 }

      it "renders evidence vault successfully" do
        get case_evidence_vault_index_path(case_instance)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Evidence Vault")
        expect(response.body).to include("Mitchell v. TechFlow Industries")
      end

      it "displays accessible documents" do
        document = create(:document, 
                         title: "Employee Handbook",
                         category: "company_policies",
                         access_level: "case_teams",
                         documentable: case_instance)

        get case_evidence_vault_index_path(case_instance)
        expect(response.body).to include("Employee Handbook")
        expect(response.body).to include("company_policies")
      end

      it "hides instructor-only documents" do
        instructor_doc = create(:document,
                               title: "Confidential Financial Records", 
                               access_level: "instructor_only",
                               documentable: case_instance)

        get case_evidence_vault_index_path(case_instance)
        expect(response.body).not_to include("Confidential Financial Records")
      end
    end

    context "when authenticated as instructor" do
      before { sign_in instructor }

      it "shows all documents including instructor-only" do
        instructor_doc = create(:document,
                               title: "Confidential Financial Records",
                               access_level: "instructor_only", 
                               documentable: case_instance)

        get case_evidence_vault_index_path(case_instance)
        expect(response.body).to include("Confidential Financial Records")
      end
    end

    context "when user not on case team" do
      let(:outsider) { create(:user, :student) }
      
      before { sign_in outsider }

      it "denies access" do
        get case_evidence_vault_index_path(case_instance)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /cases/:id/evidence_vault/search" do
    let!(:documents) do
      [
        create(:document, title: "Employee Handbook", tags: ["harassment", "policy"], 
               category: "company_policies", access_level: "case_teams", documentable: case_instance),
        create(:document, title: "Email Chain", tags: ["evidence", "harassment"],
               category: "communications", access_level: "case_teams", documentable: case_instance),
        create(:document, title: "Financial Records", tags: ["financials"],
               category: "financial_records", access_level: "instructor_only", documentable: case_instance)
      ]
    end

    before { sign_in student1 }

    it "searches by query term" do
      get case_evidence_vault_search_path(case_instance), params: { q: "harassment" }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
      
      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(2)
      titles = results["documents"].map { |d| d["title"] }
      expect(titles).to include("Employee Handbook", "Email Chain")
      expect(titles).not_to include("Financial Records")
    end

    it "filters by category" do
      get case_evidence_vault_search_path(case_instance), params: { category: "communications" }
      
      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Email Chain")
    end

    it "filters by tags" do
      get case_evidence_vault_search_path(case_instance), params: { tags: ["policy"] }
      
      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Employee Handbook")
    end

    it "combines search query with filters" do
      get case_evidence_vault_search_path(case_instance), 
          params: { q: "harassment", category: "company_policies" }
      
      results = JSON.parse(response.body)
      expect(results["documents"].size).to eq(1)
      expect(results["documents"].first["title"]).to eq("Employee Handbook")
    end

    it "returns empty results for no matches" do
      get case_evidence_vault_search_path(case_instance), params: { q: "nonexistent" }
      
      results = JSON.parse(response.body)
      expect(results["documents"]).to be_empty
      expect(results["total_results"]).to eq(0)
    end

    it "includes metadata in search response" do
      get case_evidence_vault_search_path(case_instance), params: { q: "harassment" }
      
      results = JSON.parse(response.body)
      expect(results["total_results"]).to eq(2)
      expect(results["search_query"]).to eq("harassment")
      expect(results["available_categories"]).to be_an(Array)
      expect(results["available_tags"]).to be_an(Array)
    end
  end

  describe "GET /cases/:id/evidence_vault/:document_id" do
    let(:document) { create(:document, title: "HR Report", documentable: case_instance, access_level: "case_teams") }
    
    before { sign_in student1 }

    it "returns document details for preview" do
      get case_evidence_vault_path(case_instance, document)
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
      
      doc_data = JSON.parse(response.body)
      expect(doc_data["title"]).to eq("HR Report")
      expect(doc_data["id"]).to eq(document.id)
    end

    it "includes existing annotations" do
      document.update!(
        annotations: [
          {
            id: SecureRandom.uuid,
            user_id: student2.id,
            user_name: "Bob Smith",
            team_id: team.id,
            content: "Important finding on page 3",
            page: 3,
            created_at: 1.hour.ago.iso8601
          }
        ]
      )

      get case_evidence_vault_path(case_instance, document)
      
      doc_data = JSON.parse(response.body)
      expect(doc_data["annotations"]).to be_an(Array)
      expect(doc_data["annotations"].first["content"]).to eq("Important finding on page 3")
      expect(doc_data["annotations"].first["user_name"]).to eq("Bob Smith")
    end

    it "denies access to restricted documents" do
      restricted_doc = create(:document, access_level: "instructor_only", documentable: case_instance)
      
      get case_evidence_vault_path(case_instance, restricted_doc)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /cases/:id/evidence_vault/:document_id/annotate" do
    let(:document) { create(:document, title: "Evidence Doc", documentable: case_instance, access_level: "case_teams") }
    
    before { sign_in student1 }

    it "adds annotation successfully" do
      post annotate_case_evidence_vault_path(case_instance, document), params: {
        annotation: {
          content: "This supports our argument about timeline",
          page: 2
        }
      }

      expect(response).to have_http_status(:success)
      
      document.reload
      latest_annotation = document.annotations.last
      expect(latest_annotation["content"]).to eq("This supports our argument about timeline")
      expect(latest_annotation["user_id"]).to eq(student1.id)
      expect(latest_annotation["user_name"]).to eq("Alice Johnson")
      expect(latest_annotation["team_id"]).to eq(team.id)
      expect(latest_annotation["page"]).to eq(2)
    end

    it "validates annotation content" do
      post annotate_case_evidence_vault_path(case_instance, document), params: {
        annotation: {
          content: "",
          page: 1
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      
      error_data = JSON.parse(response.body)
      expect(error_data["errors"]).to include("Content cannot be blank")
    end

    it "requires valid page number" do
      post annotate_case_evidence_vault_path(case_instance, document), params: {
        annotation: {
          content: "Valid content",
          page: -1
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "denies annotation on restricted documents" do
      restricted_doc = create(:document, access_level: "instructor_only", documentable: case_instance)
      
      post annotate_case_evidence_vault_path(case_instance, restricted_doc), params: {
        annotation: {
          content: "Trying to annotate",
          page: 1
        }
      }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PUT /cases/:id/evidence_vault/:document_id/tags" do
    let(:document) { create(:document, title: "Test Doc", tags: ["original"], documentable: case_instance, access_level: "case_teams") }
    
    before { sign_in student1 }

    it "updates document tags successfully" do
      put update_tags_case_evidence_vault_path(case_instance, document), params: {
        tags: ["original", "updated", "new-tag"]
      }

      expect(response).to have_http_status(:success)
      
      document.reload
      expect(document.tags).to include("original", "updated", "new-tag")
    end

    it "removes old tags not in new list" do
      put update_tags_case_evidence_vault_path(case_instance, document), params: {
        tags: ["completely-new"]
      }

      document.reload
      expect(document.tags).to eq(["completely-new"])
      expect(document.tags).not_to include("original")
    end

    it "validates tag format" do
      put update_tags_case_evidence_vault_path(case_instance, document), params: {
        tags: ["valid", "", "  ", "also-valid"]
      }

      expect(response).to have_http_status(:unprocessable_entity)
      
      error_data = JSON.parse(response.body)
      expect(error_data["errors"]).to include("Tags cannot be blank")
    end
  end

  describe "POST /cases/:id/evidence_vault/bundles" do
    let!(:doc1) { create(:document, title: "Doc 1", documentable: case_instance, access_level: "case_teams") }
    let!(:doc2) { create(:document, title: "Doc 2", documentable: case_instance, access_level: "case_teams") }
    
    before { sign_in student1 }

    it "creates evidence bundle successfully" do
      post case_evidence_vault_bundles_path(case_instance), params: {
        bundle: {
          name: "Harassment Evidence Package",
          document_ids: [doc1.id, doc2.id]
        }
      }

      expect(response).to have_http_status(:created)
      
      bundle_data = JSON.parse(response.body)
      expect(bundle_data["name"]).to eq("Harassment Evidence Package")
      expect(bundle_data["document_count"]).to eq(2)
      expect(bundle_data["documents"]).to be_an(Array)
    end

    it "validates bundle name" do
      post case_evidence_vault_bundles_path(case_instance), params: {
        bundle: {
          name: "",
          document_ids: [doc1.id]
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "validates at least one document" do
      post case_evidence_vault_bundles_path(case_instance), params: {
        bundle: {
          name: "Empty Bundle",
          document_ids: []
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      
      error_data = JSON.parse(response.body)
      expect(error_data["errors"]).to include("Bundle must contain at least one document")
    end

    it "ignores documents user cannot access" do
      restricted_doc = create(:document, access_level: "instructor_only", documentable: case_instance)
      
      post case_evidence_vault_bundles_path(case_instance), params: {
        bundle: {
          name: "Mixed Bundle",
          document_ids: [doc1.id, restricted_doc.id]
        }
      }

      expect(response).to have_http_status(:created)
      
      bundle_data = JSON.parse(response.body)
      expect(bundle_data["document_count"]).to eq(1) # Only accessible doc included
    end
  end

  describe "performance considerations" do
    before { sign_in student1 }

    context "with large document sets" do
      before do
        create_list(:document, 100, documentable: case_instance, access_level: "case_teams")
      end

      it "loads evidence vault efficiently" do
        start_time = Time.current
        get case_evidence_vault_index_path(case_instance)
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end

      it "paginates search results" do
        get case_evidence_vault_search_path(case_instance), params: { page: 1, per_page: 20 }
        
        results = JSON.parse(response.body)
        expect(results["documents"].size).to eq(20)
        expect(results["pagination"]).to include("current_page", "total_pages", "total_results")
      end
    end
  end

  describe "security considerations" do
    before { sign_in student1 }

    it "prevents SQL injection in search" do
      malicious_query = "'; DROP TABLE documents; --"
      
      get case_evidence_vault_search_path(case_instance), params: { q: malicious_query }
      
      expect(response).to have_http_status(:success)
      expect(Document.count).to be > 0 # Table still exists
    end

    it "sanitizes annotation content" do
      document = create(:document, documentable: case_instance, access_level: "case_teams")
      
      post annotate_case_evidence_vault_path(case_instance, document), params: {
        annotation: {
          content: "<script>alert('xss')</script>Safe content",
          page: 1
        }
      }

      document.reload
      annotation = document.annotations.last
      expect(annotation["content"]).not_to include("<script>")
      expect(annotation["content"]).to include("Safe content")
    end
  end
end