# frozen_string_literal: true

# Serializer for TeamMember model following JSON:API specification
class TeamMemberSerializer
  include JSONAPI::Serializer

  attributes :role,
    :created_at,
    :updated_at

  attribute :display_name, &:display_name
  attribute :is_manager, &:manager?

  belongs_to :team, serializer: TeamSerializer
  belongs_to :user, serializer: UserSerializer
end
