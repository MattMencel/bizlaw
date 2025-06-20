# frozen_string_literal: true

class OrganizationSerializer
  include JSONAPI::Serializer

  attributes :name,
    :domain,
    :slug,
    :license_type,
    :max_courses,
    :max_students,
    :active,
    :created_at,
    :updated_at

  attribute :display_name, &:display_name
end
