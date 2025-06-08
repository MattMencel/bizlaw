# frozen_string_literal: true

class CreateJwtDenylist < ActiveRecord::Migration[7.1]
  def change
    create_table :jwt_denylist do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false

      t.timestamps
      t.index :jti, unique: true
      t.index :exp
    end
  end
end
