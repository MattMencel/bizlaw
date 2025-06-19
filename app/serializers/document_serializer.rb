# frozen_string_literal: true

# Serializer for Document model using JSON:API specification
class DocumentSerializer
  include JSONAPI::Serializer

  attributes :title,
    :description,
    :document_type,
    :status,
    :file_url,
    :file_type,
    :file_size,
    :created_at,
    :updated_at,
    :finalized_at,
    :archived_at

  belongs_to :created_by, serializer: :user
  belongs_to :documentable, polymorphic: true

  attribute :file_url do |document|
    Rails.application.routes.url_helpers.rails_blob_url(document.file) if document.file.attached?
  end

  attribute :file_type do |document|
    document.file.content_type if document.file.attached?
  end

  attribute :file_size do |document|
    document.file.byte_size if document.file.attached?
  end
end
