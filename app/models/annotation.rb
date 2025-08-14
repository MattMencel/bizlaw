# frozen_string_literal: true

class Annotation < ApplicationRecord
  include HasUuid
  include HasTimestamps

  # Associations
  belongs_to :document
  belongs_to :user

  # Validations
  validates :content, presence: true
  validates :x_position, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :y_position, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :page_number, presence: true, numericality: {greater_than: 0}

  # Scopes
  scope :for_page, ->(page) { where(page_number: page) }
  scope :by_position, -> { order(:page_number, :y_position, :x_position) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def position
    {x: x_position, y: y_position, page: page_number}
  end
end
