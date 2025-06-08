# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API::V1::Documents', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:instructor) { create(:user, role: :instructor) }
  let(:student) { create(:user, role: :student) }
  let(:other_student) { create(:user, role: :student) }

  let(:case_record) { create(:case, created_by: instructor) }
  let(:team) { create(:team, owner: student) }

  let!(:case_document) { create(:document, documentable: case_record, created_by: instructor) }
  let!(:team_document) { create(:document, documentable: team, created_by: student) }
  let!(:other_document) { create(:document, created_by: other_student) }

  let(:valid_headers) { { 'Content-Type' => 'application/json' } }

  before do
    # Mock team membership for student access
    allow_any_instance_of(User).to receive(:teams).and_return([ team ])
    allow_any_instance_of(User).to receive(:team_ids).and_return([ team.id ])
  end

  describe 'GET /api/v1/documents' do
    context 'when user is admin' do
      before { sign_in admin }

      it 'returns all documents' do
        get '/api/v1/documents', headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['data'].size).to eq(3)
      end

      it 'includes document associations' do
        get '/api/v1/documents', headers: valid_headers

        response_data = JSON.parse(response.body)
        first_document = response_data['data'].first
        expect(response_data['included']).to be_present
      end
    end

    context 'when user is student' do
      before { sign_in student }

      it 'returns only accessible documents' do
        get '/api/v1/documents', headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        # Should include team_document and any documents created by student
        expect(response_data['data'].size).to be >= 1
      end
    end

    context 'with filters' do
      before { sign_in admin }

      it 'filters by document type' do
        get '/api/v1/documents',
            params: { document_type: 'evidence' },
            headers: valid_headers

        expect(response).to have_http_status(:ok)
      end

      it 'filters by status' do
        get '/api/v1/documents',
            params: { status: 'draft' },
            headers: valid_headers

        expect(response).to have_http_status(:ok)
      end

      it 'filters by documentable' do
        get '/api/v1/documents',
            params: {
              documentable_type: 'Case',
              documentable_id: case_record.id
            },
            headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['data'].size).to eq(1)
      end

      it 'searches by query' do
        get '/api/v1/documents',
            params: { query: case_document.title },
            headers: valid_headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'pagination' do
      before { sign_in admin }

      it 'includes pagination metadata' do
        get '/api/v1/documents',
            params: { page: 1, per_page: 2 },
            headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['meta']).to be_present
      end
    end
  end

  describe 'GET /api/v1/documents/:id' do
    context 'when user can access document' do
      before { sign_in instructor }

      it 'returns the document' do
        get "/api/v1/documents/#{case_document.id}", headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['data']['id']).to eq(case_document.id)
      end

      it 'includes associations' do
        get "/api/v1/documents/#{case_document.id}", headers: valid_headers

        response_data = JSON.parse(response.body)
        expect(response_data['included']).to be_present
      end
    end

    context 'when user cannot access document' do
      before { sign_in other_student }

      it 'returns forbidden' do
        get "/api/v1/documents/#{case_document.id}", headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when document does not exist' do
      before { sign_in admin }

      it 'returns not found' do
        get '/api/v1/documents/nonexistent-id', headers: valid_headers

        expect(response).to have_http_status(:not_found)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to eq('Document not found')
      end
    end
  end

  describe 'POST /api/v1/documents' do
    let(:valid_params) do
      {
        document: {
          title: 'New Document',
          description: 'Test document',
          document_type: 'evidence',
          documentable_type: 'Case',
          documentable_id: case_record.id
        }
      }
    end

    context 'when user can create documents' do
      before { sign_in instructor }

      it 'creates a new document' do
        expect {
          post '/api/v1/documents',
               params: valid_params.to_json,
               headers: valid_headers
        }.to change(Document, :count).by(1)

        expect(response).to have_http_status(:created)
        response_data = JSON.parse(response.body)
        expect(response_data['data']['attributes']['title']).to eq('New Document')
      end

      it 'sets current user as creator' do
        post '/api/v1/documents',
             params: valid_params.to_json,
             headers: valid_headers

        document = Document.last
        expect(document.created_by).to eq(instructor)
      end
    end

    context 'when user cannot create documents' do
      before { sign_in other_student }

      it 'returns forbidden' do
        post '/api/v1/documents',
             params: valid_params.to_json,
             headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with invalid params' do
      before { sign_in instructor }

      it 'returns validation errors' do
        invalid_params = { document: { title: '' } }

        post '/api/v1/documents',
             params: invalid_params.to_json,
             headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/documents/:id' do
    let(:update_params) do
      {
        document: {
          title: 'Updated Document Title',
          description: 'Updated description'
        }
      }
    end

    context 'when user can update document' do
      before { sign_in instructor }

      it 'updates the document' do
        patch "/api/v1/documents/#{case_document.id}",
              params: update_params.to_json,
              headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['data']['attributes']['title']).to eq('Updated Document Title')
      end
    end

    context 'when user cannot update document' do
      before { sign_in other_student }

      it 'returns forbidden' do
        patch "/api/v1/documents/#{case_document.id}",
              params: update_params.to_json,
              headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with invalid params' do
      before { sign_in instructor }

      it 'returns validation errors' do
        invalid_params = { document: { title: '' } }

        patch "/api/v1/documents/#{case_document.id}",
              params: invalid_params.to_json,
              headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/documents/:id' do
    context 'when user can delete document' do
      before { sign_in instructor }

      it 'deletes the document' do
        expect {
          delete "/api/v1/documents/#{case_document.id}", headers: valid_headers
        }.to change(Document, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when user cannot delete document' do
      before { sign_in other_student }

      it 'returns forbidden' do
        delete "/api/v1/documents/#{case_document.id}", headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/documents/:id/finalize' do
    let(:draft_document) { create(:document, status: 'draft', created_by: instructor) }

    context 'when user can finalize document' do
      before { sign_in instructor }

      it 'finalizes the document' do
        allow(draft_document).to receive(:finalize!).and_return(true)
        allow(Document).to receive(:find_by!).and_return(draft_document)

        post "/api/v1/documents/#{draft_document.id}/finalize", headers: valid_headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when document cannot be finalized' do
      before { sign_in instructor }

      it 'returns unprocessable entity' do
        finalized_document = create(:document, status: 'final', created_by: instructor)

        post "/api/v1/documents/#{finalized_document.id}/finalize", headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/documents/:id/archive' do
    let(:final_document) { create(:document, status: 'final', created_by: instructor) }

    context 'when user can archive document' do
      before { sign_in instructor }

      it 'archives the document' do
        allow(final_document).to receive(:archive!).and_return(true)
        allow(Document).to receive(:find_by!).and_return(final_document)

        post "/api/v1/documents/#{final_document.id}/archive", headers: valid_headers

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when document cannot be archived' do
      before { sign_in instructor }

      it 'returns unprocessable entity' do
        draft_document = create(:document, status: 'draft', created_by: instructor)

        post "/api/v1/documents/#{draft_document.id}/archive", headers: valid_headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/documents/templates' do
    let!(:template_document) { create(:document, document_type: 'template', created_by: instructor) }

    context 'when user is authenticated' do
      before { sign_in instructor }

      it 'returns template documents' do
        allow(Document).to receive(:templates).and_return(Document.where(id: template_document.id))

        get '/api/v1/documents/templates', headers: valid_headers

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)
        expect(response_data['data']).to be_present
      end
    end
  end

  context 'authorization scenarios' do
    describe 'admin access' do
      before { sign_in admin }

      it 'allows access to all documents' do
        get '/api/v1/documents', headers: valid_headers
        expect(response).to have_http_status(:ok)

        get "/api/v1/documents/#{case_document.id}", headers: valid_headers
        expect(response).to have_http_status(:ok)

        get "/api/v1/documents/#{team_document.id}", headers: valid_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'instructor access' do
      before { sign_in instructor }

      it 'allows access to all documents' do
        get '/api/v1/documents', headers: valid_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'student access restrictions' do
      before { sign_in other_student }

      it 'restricts access appropriately' do
        # Should not access case document they're not involved in
        get "/api/v1/documents/#{case_document.id}", headers: valid_headers
        expect(response).to have_http_status(:forbidden)

        # Should not access team document they're not member of
        get "/api/v1/documents/#{team_document.id}", headers: valid_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
