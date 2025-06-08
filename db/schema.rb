# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_07_213438) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "case_difficulty", ["beginner", "intermediate", "advanced"]
  create_enum "case_status", ["not_started", "in_progress", "submitted", "reviewed", "completed"]
  create_enum "case_type", ["sexual_harassment", "discrimination", "wrongful_termination", "contract_dispute", "intellectual_property"]
  create_enum "document_status", ["draft", "final", "archived"]
  create_enum "document_type", ["template", "submission", "feedback", "resource"]
  create_enum "team_member_role", ["member", "manager"]
  create_enum "user_role", ["student", "instructor", "admin"]

  create_table "case_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.uuid "user_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["case_id"], name: "index_case_events_on_case_id"
    t.index ["created_at"], name: "index_case_events_on_created_at"
    t.index ["deleted_at"], name: "index_case_events_on_deleted_at"
    t.index ["event_type"], name: "index_case_events_on_event_type"
    t.index ["user_id"], name: "index_case_events_on_user_id"
  end

  create_table "case_teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.uuid "team_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id", "role"], name: "index_case_teams_on_case_id_and_role", unique: true
    t.index ["case_id", "team_id"], name: "index_case_teams_on_case_id_and_team_id", unique: true
    t.index ["case_id"], name: "index_case_teams_on_case_id"
    t.index ["team_id"], name: "index_case_teams_on_team_id"
  end

  create_table "case_types", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "reference_number", null: false
    t.enum "status", default: "not_started", null: false, enum_type: "case_status"
    t.enum "difficulty_level", null: false, enum_type: "case_difficulty"
    t.enum "case_type", null: false, enum_type: "case_type"
    t.jsonb "plaintiff_info", default: {}, null: false
    t.jsonb "defendant_info", default: {}, null: false
    t.jsonb "legal_issues", default: [], null: false
    t.datetime "due_date"
    t.datetime "published_at"
    t.datetime "archived_at"
    t.uuid "team_id", null: false
    t.uuid "created_by_id", null: false
    t.uuid "updated_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index "lower((title)::text)", name: "index_cases_on_lower_title"
    t.index ["case_type"], name: "index_cases_on_case_type"
    t.index ["created_at"], name: "index_cases_on_created_at"
    t.index ["created_by_id"], name: "index_cases_on_created_by_id"
    t.index ["deleted_at", "created_at"], name: "index_cases_on_deleted_at_created_at"
    t.index ["deleted_at"], name: "index_cases_on_deleted_at"
    t.index ["difficulty_level"], name: "index_cases_on_difficulty_level"
    t.index ["reference_number"], name: "index_cases_on_reference_number", unique: true
    t.index ["status", "difficulty_level", "case_type"], name: "index_cases_on_status_difficulty_type"
    t.index ["status"], name: "index_cases_on_status"
    t.index ["team_id"], name: "index_cases_on_team_id"
    t.index ["updated_by_id"], name: "index_cases_on_updated_by_id"
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.enum "document_type", null: false, enum_type: "document_type"
    t.enum "status", default: "draft", null: false, enum_type: "document_status"
    t.string "file_url"
    t.string "file_type"
    t.integer "file_size"
    t.datetime "finalized_at"
    t.datetime "archived_at"
    t.string "documentable_type", null: false
    t.uuid "documentable_id", null: false
    t.uuid "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["created_by_id"], name: "index_documents_on_created_by_id"
    t.index ["deleted_at"], name: "index_documents_on_deleted_at"
    t.index ["document_type"], name: "index_documents_on_document_type"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable"
    t.index ["status"], name: "index_documents_on_status"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylist_on_exp"
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "team_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.enum "role", default: "member", null: false, enum_type: "team_member_role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_team_members_on_created_at"
    t.index ["deleted_at", "user_id", "team_id"], name: "index_team_members_on_deleted_at_user_team"
    t.index ["deleted_at"], name: "index_team_members_on_deleted_at"
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id", "team_id"], name: "index_team_members_active_user_team", where: "(deleted_at IS NULL)"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.integer "max_members", null: false
    t.uuid "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["name", "owner_id"], name: "index_teams_on_name_and_owner_id", unique: true
    t.index ["owner_id"], name: "index_teams_on_owner_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.enum "role", default: "student", null: false, enum_type: "user_role"
    t.string "provider"
    t.string "uid"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "active", default: true, null: false
    t.index "lower((first_name)::text), lower((last_name)::text)", name: "index_users_on_lower_names"
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "case_events", "cases", on_delete: :cascade
  add_foreign_key "case_events", "users"
  add_foreign_key "case_teams", "cases"
  add_foreign_key "case_teams", "teams"
  add_foreign_key "cases", "teams"
  add_foreign_key "cases", "users", column: "created_by_id"
  add_foreign_key "cases", "users", column: "updated_by_id"
  add_foreign_key "documents", "users", column: "created_by_id"
  add_foreign_key "team_members", "teams", on_delete: :cascade
  add_foreign_key "team_members", "users"
  add_foreign_key "teams", "users", column: "owner_id"
end
