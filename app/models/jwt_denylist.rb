# frozen_string_literal: true

class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylist"

  # The jwt_denylist table has no deleted_at column, so opt out of the
  # SoftDeletable default scope that ApplicationRecord applies app-wide.
  self.default_scopes = []
end
