# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :email,
             :first_name,
             :last_name,
             :role,
             :avatar_url,
             :created_at,
             :updated_at

  attribute :full_name do |user|
    user.full_name
  end

  attribute :teams do |user|
    user.team_members.includes(:team).map do |member|
      {
        id: member.team.id,
        name: member.team.name,
        role: member.role
      }
    end
  end

  attribute :owned_teams do |user|
    user.owned_teams.map do |team|
      {
        id: team.id,
        name: team.name
      }
    end
  end
end
