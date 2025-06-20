class DocumentSearchController < ApplicationController
  include ImpersonationReadOnly

  before_action :authenticate_user!

  def index
    @query = params[:q]
    @documents = []

    if @query.present?
      @documents = Document.accessible_by(current_user)
        .where("title ILIKE ? OR content ILIKE ?", "%#{@query}%", "%#{@query}%")
        .page(params[:page])
    end
  end

  def advanced
    @search_form = DocumentSearchForm.new(search_params)
    @documents = @search_form.results.page(params[:page]) if @search_form.valid?
  end

  def search
    @query = params[:q]
    @case_id = params[:case_id]

    documents = Document.accessible_by(current_user)
    documents = documents.joins(:case).where(cases: {id: @case_id}) if @case_id.present?

    if @query.present?
      documents = documents.where("title ILIKE ? OR content ILIKE ?", "%#{@query}%", "%#{@query}%")
    end

    @documents = documents.page(params[:page])

    respond_to do |format|
      format.html { render :index }
      format.json { render json: DocumentSerializer.new(@documents).serializable_hash }
    end
  end

  private

  def search_params
    params.permit(:title, :content, :document_type, :case_id, :created_after, :created_before)
  end
end
