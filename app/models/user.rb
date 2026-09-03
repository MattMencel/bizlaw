# frozen_string_literal: true

# A person in an Organization. Attribution is what lets a Team be a single party
# without the game losing track of the people in it, so every spend names one.
#
# This is the shape a Docket row points at and nothing more: authentication, the
# roster and the Pairing that joins people to a Side are not built here.
class User < ApplicationRecord
  retention :skeleton

  belongs_to :organization

  has_many :docket_entries,
    class_name: "DocketEntry",
    foreign_key: :spent_by_user_id,
    inverse_of: :spent_by,
    dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, uniqueness: {scope: :organization_id}
end
