# frozen_string_literal: true

class CourseSerializer
  include JSONAPI::Serializer

  attributes :title,
    :course_code,
    :year,
    :semester,
    :start_date,
    :end_date,
    :active,
    :created_at,
    :updated_at

  attribute :display_name, &:display_name
  attribute :full_title, &:full_title
  attribute :semester_display, &:semester_display

  belongs_to :instructor, serializer: UserSerializer
  belongs_to :organization
end
