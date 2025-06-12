class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations, id: :uuid do |t|
      t.string :email, null: false
      t.string :role, null: false
      t.references :invited_by, polymorphic: true, null: false, type: :uuid
      t.references :organization, null: true, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.string :status, default: 'pending', null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.boolean :shareable, default: false, null: false
      t.boolean :org_admin, default: false, null: false

      t.timestamps
    end

    add_index :invitations, :email
    add_index :invitations, :role
    add_index :invitations, :token, unique: true
    add_index :invitations, :status
    add_index :invitations, :shareable
    add_index :invitations, [:email, :organization_id], unique: true, where: "status = 'pending'"
  end
end
