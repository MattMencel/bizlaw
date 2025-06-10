class CreateCourseInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :course_invitations, id: :uuid do |t|
      t.uuid :course_id, null: false
      t.string :token, null: false
      t.string :name # Optional name for the invitation
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :current_uses, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :course_invitations, :course_id
    add_index :course_invitations, :token, unique: true
    add_index :course_invitations, :active
    add_index :course_invitations, :expires_at
    add_index :course_invitations, :deleted_at

    add_foreign_key :course_invitations, :courses
  end
end
