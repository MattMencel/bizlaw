# frozen_string_literal: true

# Serializer for Case model following JSON:API specification
class CaseSerializer
  include JSONAPI::Serializer

  attributes :title,
             :description,
             :reference_number,
             :status,
             :difficulty_level,
             :case_type,
             :plaintiff_info,
             :defendant_info,
             :legal_issues,
             :due_date,
             :published_at,
             :archived_at,
             :created_at,
             :updated_at

  attribute :started, &:started?
  attribute :completed, &:completed?
  attribute :can_submit, &:can_submit?
  attribute :can_review, &:can_review?

  belongs_to :team
  belongs_to :created_by, serializer: UserSerializer
  belongs_to :updated_by, serializer: UserSerializer
  belongs_to :case_type
  has_many :case_teams
  has_many :teams, through: :case_teams
  has_many :documents
  has_many :case_events
end
