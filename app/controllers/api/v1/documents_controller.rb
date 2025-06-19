# frozen_string_literal: true

module Api
  module V1
    # API endpoints for managing documents with proper authorization and filtering
    class DocumentsController < BaseController
      before_action :set_document, only: %i[show update destroy finalize archive]

      def index
        @documents = policy_scope(Document).includes(:created_by, :documentable)
        @documents = filter_documents(@documents)
        render json: DocumentSerializer.new(
          @documents,
          include: %i[created_by documentable],
          meta: pagination_meta(@documents)
        ).serializable_hash
      end

      def show
        authorize @document
        render json: DocumentSerializer.new(
          @document,
          include: %i[created_by documentable]
        ).serializable_hash
      end

      def create
        @document = Document.new(document_params)
        @document.created_by = current_user
        authorize @document

        if @document.save
          render json: DocumentSerializer.new(
            @document,
            include: %i[created_by documentable]
          ).serializable_hash, status: :created
        else
          render_errors(@document.errors)
        end
      end

      def update
        authorize @document
        if @document.update(document_params)
          render json: DocumentSerializer.new(
            @document,
            include: %i[created_by documentable]
          ).serializable_hash
        else
          render_errors(@document.errors)
        end
      end

      def destroy
        authorize @document
        @document.destroy
        head :no_content
      end

      def finalize
        authorize @document, :finalize?
        if @document.finalize!
          render json: DocumentSerializer.new(
            @document,
            include: %i[created_by documentable]
          ).serializable_hash
        else
          render json: {error: "Cannot finalize document"}, status: :unprocessable_entity
        end
      end

      def archive
        authorize @document, :archive?
        if @document.archive!
          render json: DocumentSerializer.new(
            @document,
            include: %i[created_by documentable]
          ).serializable_hash
        else
          render json: {error: "Cannot archive document"}, status: :unprocessable_entity
        end
      end

      def templates
        @templates = Document.templates.accessible_by(current_user)
        render json: DocumentSerializer.new(
          @templates,
          include: %i[created_by documentable],
          meta: pagination_meta(@templates)
        ).serializable_hash
      end

      private

      def set_document
        @document = Document.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {error: "Document not found"}, status: :not_found
      end

      def filter_documents(documents)
        documents = documents.search_by_title(params[:query]) if params[:query].present?
        documents = documents.by_type(params[:document_type]) if params[:document_type].present?
        documents = documents.by_status(params[:status]) if params[:status].present?

        if params[:documentable_type].present? && params[:documentable_id].present?
          documents = documents.for_documentable(params[:documentable_type], params[:documentable_id])
        end

        documents.page(params[:page]).per(params[:per_page])
      end

      def document_params
        params.require(:document).permit(
          :title,
          :description,
          :document_type,
          :status,
          :file,
          :documentable_type,
          :documentable_id
        )
      end
    end
  end
end
