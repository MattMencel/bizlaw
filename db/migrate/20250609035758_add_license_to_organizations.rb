# frozen_string_literal: true

class AddLicenseToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_reference :organizations, :license, null: true, foreign_key: true, type: :uuid
  end
end
