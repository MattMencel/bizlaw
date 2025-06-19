# frozen_string_literal: true

# Serializer for Team model following JSON:API specification
class TeamSerializer
  include JSONAPI::Serializer

  attributes :name,
    :description,
    :max_members,
    :created_at,
    :updated_at

  attribute :member_count, &:member_count
  attribute :is_full, &:full?

  belongs_to :owner, serializer: UserSerializer
  has_many :team_members, serializer: TeamMemberSerializer
  has_many :users, serializer: UserSerializer
end
