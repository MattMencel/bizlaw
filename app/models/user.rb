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

  has_many :day_commitments,
    foreign_key: :committed_by_user_id,
    inverse_of: :committed_by,
    dependent: :restrict_with_error

  has_many :staged_offers,
    foreign_key: :staged_by_user_id,
    inverse_of: :staged_by,
    dependent: :restrict_with_error

  has_many :committed_offers,
    foreign_key: :staged_by_user_id,
    inverse_of: :staged_by,
    dependent: :restrict_with_error

  has_many :seconded_offers,
    class_name: "CommittedOffer",
    foreign_key: :seconded_by_user_id,
    inverse_of: :seconded_by,
    dependent: :restrict_with_error

  has_many :offer_acceptances,
    foreign_key: :accepted_by_user_id,
    inverse_of: :accepted_by,
    dependent: :restrict_with_error

  has_many :seconded_acceptances,
    class_name: "OfferAcceptance",
    foreign_key: :seconded_by_user_id,
    inverse_of: :seconded_by,
    dependent: :restrict_with_error

  has_many :second_waivers,
    foreign_key: :granted_by_user_id,
    inverse_of: :granted_by,
    dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, uniqueness: {scope: :organization_id}
end
