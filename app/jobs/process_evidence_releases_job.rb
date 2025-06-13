# frozen_string_literal: true

class ProcessEvidenceReleasesJob < ApplicationJob
  queue_as :default

  def perform
    # Process all pending evidence releases that are ready
    EvidenceRelease.ready_for_release.pending_release.find_each do |evidence_release|
      next unless evidence_release.ready_for_release?
      
      if evidence_release.release!
        Rails.logger.info "Released evidence: #{evidence_release.evidence_type} for simulation #{evidence_release.simulation.id}"
      else
        Rails.logger.error "Failed to release evidence: #{evidence_release.id}"
      end
    end
  end
end