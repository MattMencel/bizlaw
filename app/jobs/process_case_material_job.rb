# frozen_string_literal: true

class ProcessCaseMaterialJob < ApplicationJob
  queue_as :default

  def perform(document)
    return unless document.case_material?

    # Extract text content for search indexing
    document.update_searchable_content!

    # Log the processing
    Rails.logger.info "Processed case material: #{document.title} (#{document.id})"
  rescue => e
    Rails.logger.error "Failed to process case material #{document.id}: #{e.message}"
    # Don't re-raise to avoid job failures
  end
end
