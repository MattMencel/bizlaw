require "rails_helper"

RSpec.describe AnnotationsController, type: :controller do
  let(:user) { create(:user) }
  let(:annotation) { create(:annotation, user: user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns user annotations" do
      annotation1 = create(:annotation, user: user)
      annotation2 = create(:annotation, user: user)
      create(:annotation) # Different user's annotation

      get :index

      expect(assigns(:annotations)).to include(annotation1, annotation2)
      expect(assigns(:annotations)).not_to include(create(:annotation))
    end
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, params: {id: annotation.id}
      expect(response).to be_successful
    end

    it "assigns the requested annotation" do
      get :show, params: {id: annotation.id}
      expect(assigns(:annotation)).to eq(annotation)
    end

    it "raises error when accessing other user annotation" do
      other_annotation = create(:annotation)
      expect {
        get :show, params: {id: other_annotation.id}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) {
      {
        content: "Test annotation",
        document_id: create(:document).id,
        x_position: 100,
        y_position: 200,
        page_number: 1
      }
    }

    context "with valid parameters" do
      it "creates a new annotation" do
        expect {
          post :create, params: {annotation: valid_attributes}
        }.to change(Annotation, :count).by(1)
      end

      it "redirects to the created annotation" do
        post :create, params: {annotation: valid_attributes}
        expect(response).to redirect_to(Annotation.last)
      end
    end

    context "with invalid parameters" do
      it "does not create a new annotation" do
        expect {
          post :create, params: {annotation: {content: ""}}
        }.not_to change(Annotation, :count)
      end

      it "renders the new template" do
        post :create, params: {annotation: {content: ""}}
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PATCH #update" do
    let(:new_attributes) {
      {content: "Updated annotation content"}
    }

    it "updates the requested annotation" do
      patch :update, params: {id: annotation.id, annotation: new_attributes}
      annotation.reload
      expect(annotation.content).to eq("Updated annotation content")
    end

    it "redirects to the annotation" do
      patch :update, params: {id: annotation.id, annotation: new_attributes}
      expect(response).to redirect_to(annotation)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested annotation" do
      annotation # Create the annotation
      expect {
        delete :destroy, params: {id: annotation.id}
      }.to change(Annotation, :count).by(-1)
    end

    it "redirects to the annotations list" do
      delete :destroy, params: {id: annotation.id}
      expect(response).to redirect_to(annotations_path)
    end
  end

  describe "GET #search" do
    let!(:matching_annotation) { create(:annotation, user: user, content: "searchable content") }
    let!(:non_matching_annotation) { create(:annotation, user: user, content: "different content") }

    it "returns annotations matching the search query" do
      get :search, params: {q: "searchable"}

      expect(assigns(:annotations)).to include(matching_annotation)
      expect(assigns(:annotations)).not_to include(non_matching_annotation)
    end

    it "returns all annotations when no query provided" do
      get :search

      expect(assigns(:annotations)).to include(matching_annotation, non_matching_annotation)
    end
  end
end
