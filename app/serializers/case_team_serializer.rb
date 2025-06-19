# frozen_string_literal: true

# Serializer for CaseTeam model following JSON:API specification
class CaseTeamSerializer
  include JSONAPI::Serializer

  attributes :role,
    :created_at,
    :updated_at

  belongs_to :case
  belongs_to :team
end
