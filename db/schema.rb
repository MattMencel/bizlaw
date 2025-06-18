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

ActiveRecord::Schema[8.0].define(version: 2025_06_18_130233) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "case_difficulty", ["beginner", "intermediate", "advanced"]
  create_enum "case_status", ["not_started", "in_progress", "submitted", "reviewed", "completed"]
  create_enum "case_type", ["sexual_harassment", "discrimination", "wrongful_termination", "contract_dispute", "intellectual_property"]
  create_enum "document_status", ["draft", "final", "archived"]
  create_enum "document_type", ["template", "submission", "feedback", "resource"]
  create_enum "event_type", ["media_attention", "witness_change", "ipo_delay", "court_deadline", "additional_evidence", "expert_testimony"]
  create_enum "feedback_type", ["offer_reaction", "strategy_guidance", "pressure_response", "settlement_satisfaction"]
  create_enum "mood_level", ["very_unhappy", "unhappy", "neutral", "satisfied", "very_satisfied"]
  create_enum "offer_type", ["initial_demand", "counteroffer", "final_offer"]
  create_enum "outcome_type", ["plaintiff_victory", "defendant_victory", "split_decision", "no_award"]
  create_enum "pressure_escalation", ["low", "moderate", "high"]
  create_enum "round_status", ["pending", "active", "plaintiff_submitted", "defendant_submitted", "both_submitted", "completed"]
  create_enum "simulation_status", ["setup", "active", "paused", "completed", "arbitration"]
  create_enum "team_member_role", ["member", "manager"]
  create_enum "user_role", ["student", "instructor", "admin"]

  create_table "ai_usage_alerts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "alert_type", null: false
    t.decimal "threshold_value", precision: 10, scale: 6, null: false
    t.decimal "current_value", precision: 10, scale: 6, null: false
    t.string "status", default: "active", null: false
    t.text "message"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "acknowledged_at"
    t.string "acknowledged_by"
    t.datetime "resolved_at"
    t.string "resolved_by"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_type", "status"], name: "index_ai_usage_alerts_on_type_and_status"
    t.index ["alert_type"], name: "index_ai_usage_alerts_on_alert_type"
    t.index ["created_at"], name: "index_ai_usage_alerts_on_created_at"
    t.index ["deleted_at"], name: "index_ai_usage_alerts_on_deleted_at"
    t.index ["status"], name: "index_ai_usage_alerts_on_status"
  end

  create_table "ai_usage_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "model", null: false
    t.decimal "cost", precision: 10, scale: 6, default: "0.0", null: false
    t.integer "response_time_ms", null: false
    t.integer "tokens_used", default: 0
    t.string "request_type", null: false
    t.boolean "error_occurred", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "cost"], name: "index_ai_usage_logs_on_created_at_and_cost"
    t.index ["created_at"], name: "index_ai_usage_logs_on_created_at"
    t.index ["deleted_at"], name: "index_ai_usage_logs_on_deleted_at"
    t.index ["error_occurred"], name: "index_ai_usage_logs_on_error_occurred"
    t.index ["model"], name: "index_ai_usage_logs_on_model"
    t.index ["request_type"], name: "index_ai_usage_logs_on_request_type"
  end

  create_table "arbitration_outcomes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.decimal "award_amount", precision: 12, scale: 2, null: false
    t.text "rationale", null: false
    t.jsonb "factors_considered", default: {}, null: false
    t.datetime "calculated_at", null: false
    t.enum "outcome_type", null: false, enum_type: "outcome_type"
    t.decimal "evidence_strength_factor", precision: 5, scale: 2
    t.decimal "argument_quality_factor", precision: 5, scale: 2
    t.decimal "negotiation_history_factor", precision: 5, scale: 2
    t.decimal "random_variance", precision: 5, scale: 2
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["award_amount"], name: "index_arbitration_outcomes_on_award_amount"
    t.index ["calculated_at"], name: "index_arbitration_outcomes_on_calculated_at"
    t.index ["deleted_at"], name: "index_arbitration_outcomes_on_deleted_at"
    t.index ["outcome_type"], name: "index_arbitration_outcomes_on_outcome_type"
    t.index ["simulation_id"], name: "index_arbitration_outcomes_on_simulation_id"
  end

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
    t.datetime "deleted_at"
    t.index ["case_id", "role"], name: "index_case_teams_on_case_id_and_role", unique: true
    t.index ["case_id", "team_id"], name: "index_case_teams_on_case_id_and_team_id", unique: true
    t.index ["case_id"], name: "index_case_teams_on_case_id"
    t.index ["deleted_at"], name: "index_case_teams_on_deleted_at"
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
    t.uuid "created_by_id", null: false
    t.uuid "updated_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid "course_id", null: false
    t.index "lower((title)::text)", name: "index_cases_on_lower_title"
    t.index ["case_type"], name: "index_cases_on_case_type"
    t.index ["course_id"], name: "index_cases_on_course_id"
    t.index ["created_at"], name: "index_cases_on_created_at"
    t.index ["created_by_id"], name: "index_cases_on_created_by_id"
    t.index ["deleted_at", "created_at"], name: "index_cases_on_deleted_at_created_at"
    t.index ["deleted_at"], name: "index_cases_on_deleted_at"
    t.index ["difficulty_level"], name: "index_cases_on_difficulty_level"
    t.index ["reference_number"], name: "index_cases_on_reference_number", unique: true
    t.index ["status", "difficulty_level", "case_type"], name: "index_cases_on_status_difficulty_type"
    t.index ["status"], name: "index_cases_on_status"
    t.index ["updated_by_id"], name: "index_cases_on_updated_by_id"
  end

  create_table "client_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.uuid "team_id", null: false
    t.enum "feedback_type", null: false, enum_type: "feedback_type"
    t.enum "mood_level", null: false, enum_type: "mood_level"
    t.decimal "satisfaction_score", precision: 5, scale: 2, null: false
    t.text "feedback_text", null: false
    t.integer "triggered_by_round", null: false
    t.uuid "settlement_offer_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_client_feedbacks_on_deleted_at"
    t.index ["feedback_type"], name: "index_client_feedbacks_on_feedback_type"
    t.index ["mood_level"], name: "index_client_feedbacks_on_mood_level"
    t.index ["settlement_offer_id"], name: "index_client_feedbacks_on_settlement_offer_id"
    t.index ["simulation_id"], name: "index_client_feedbacks_on_simulation_id"
    t.index ["team_id"], name: "index_client_feedbacks_on_team_id"
    t.index ["triggered_by_round"], name: "index_client_feedbacks_on_triggered_by_round"
  end

  create_table "course_enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "course_id", null: false
    t.datetime "enrolled_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_enrollments_on_course_id"
    t.index ["deleted_at"], name: "index_course_enrollments_on_deleted_at"
    t.index ["enrolled_at"], name: "index_course_enrollments_on_enrolled_at"
    t.index ["status"], name: "index_course_enrollments_on_status"
    t.index ["user_id", "course_id"], name: "index_course_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_course_enrollments_on_user_id"
  end

  create_table "course_invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.string "token", null: false
    t.string "name"
    t.datetime "expires_at"
    t.integer "max_uses"
    t.integer "current_uses", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_course_invitations_on_active"
    t.index ["course_id"], name: "index_course_invitations_on_course_id"
    t.index ["deleted_at"], name: "index_course_invitations_on_deleted_at"
    t.index ["expires_at"], name: "index_course_invitations_on_expires_at"
    t.index ["token"], name: "index_course_invitations_on_token", unique: true
  end

  create_table "courses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.uuid "instructor_id", null: false
    t.string "course_code", null: false
    t.string "semester"
    t.integer "year"
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "organization_id"
    t.uuid "term_id"
    t.index ["active"], name: "index_courses_on_active"
    t.index ["course_code", "organization_id"], name: "index_courses_on_course_code_and_organization_id", unique: true
    t.index ["deleted_at"], name: "index_courses_on_deleted_at"
    t.index ["instructor_id"], name: "index_courses_on_instructor_id"
    t.index ["organization_id"], name: "index_courses_on_organization_id"
    t.index ["term_id"], name: "index_courses_on_term_id"
    t.index ["year", "semester"], name: "index_courses_on_year_and_semester"
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
    t.string "category"
    t.string "access_level", default: "case_teams"
    t.jsonb "team_restrictions", default: {}
    t.text "searchable_content"
    t.jsonb "annotations", default: []
    t.jsonb "tags", default: []
    t.index ["access_level"], name: "index_documents_on_access_level"
    t.index ["category"], name: "index_documents_on_category"
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["created_by_id"], name: "index_documents_on_created_by_id"
    t.index ["deleted_at"], name: "index_documents_on_deleted_at"
    t.index ["document_type"], name: "index_documents_on_document_type"
    t.index ["documentable_type", "documentable_id", "category"], name: "idx_on_documentable_type_documentable_id_category_6128a8a1f0"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable"
    t.index ["searchable_content"], name: "index_documents_on_searchable_content", opclass: :gin_trgm_ops, using: :gin
    t.index ["status"], name: "index_documents_on_status"
    t.index ["tags"], name: "index_documents_on_tags", using: :gin
    t.index ["team_restrictions"], name: "index_documents_on_team_restrictions", using: :gin
  end

  create_table "evidence_releases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.uuid "document_id", null: false
    t.integer "release_round"
    t.datetime "scheduled_release_at"
    t.datetime "released_at"
    t.jsonb "release_conditions", default: {}
    t.boolean "team_requested", default: false
    t.uuid "requesting_team_id"
    t.boolean "auto_release", default: true
    t.string "evidence_type"
    t.text "impact_description"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_evidence_releases_on_deleted_at"
    t.index ["document_id"], name: "index_evidence_releases_on_document_id"
    t.index ["evidence_type"], name: "index_evidence_releases_on_evidence_type"
    t.index ["release_round"], name: "index_evidence_releases_on_release_round"
    t.index ["released_at"], name: "index_evidence_releases_on_released_at"
    t.index ["requesting_team_id"], name: "index_evidence_releases_on_requesting_team_id"
    t.index ["scheduled_release_at"], name: "index_evidence_releases_on_scheduled_release_at"
    t.index ["simulation_id", "release_round"], name: "index_evidence_releases_on_simulation_id_and_release_round"
    t.index ["simulation_id", "team_requested"], name: "index_evidence_releases_on_simulation_id_and_team_requested"
    t.index ["simulation_id"], name: "index_evidence_releases_on_simulation_id"
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "role", null: false
    t.string "invited_by_type", null: false
    t.uuid "invited_by_id", null: false
    t.uuid "organization_id"
    t.string "token", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.boolean "shareable", default: false, null: false
    t.boolean "org_admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_invitations_on_deleted_at"
    t.index ["email", "organization_id"], name: "index_invitations_on_email_and_organization_id", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_type", "invited_by_id"], name: "index_invitations_on_invited_by"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["role"], name: "index_invitations_on_role"
    t.index ["shareable"], name: "index_invitations_on_shareable"
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylist_on_exp"
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "licenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "license_key", null: false
    t.string "organization_name", null: false
    t.string "contact_email", null: false
    t.string "license_type", default: "free", null: false
    t.integer "max_instructors", default: 1
    t.integer "max_students", default: 3
    t.integer "max_courses", default: 1
    t.date "expires_at"
    t.text "signature", null: false
    t.jsonb "features", default: {}
    t.boolean "active", default: true
    t.datetime "last_validated_at"
    t.string "validation_hash"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["active"], name: "index_licenses_on_active"
    t.index ["expires_at"], name: "index_licenses_on_expires_at"
    t.index ["license_key"], name: "index_licenses_on_license_key", unique: true
    t.index ["license_type"], name: "index_licenses_on_license_type"
    t.index ["organization_name"], name: "index_licenses_on_organization_name"
  end

  create_table "negotiation_rounds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.integer "round_number", null: false
    t.enum "status", default: "pending", null: false, enum_type: "round_status"
    t.datetime "deadline", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deadline"], name: "index_negotiation_rounds_on_deadline"
    t.index ["deleted_at"], name: "index_negotiation_rounds_on_deleted_at"
    t.index ["simulation_id", "round_number"], name: "index_negotiation_rounds_on_simulation_id_and_round_number", unique: true
    t.index ["simulation_id"], name: "index_negotiation_rounds_on_simulation_id"
    t.index ["status"], name: "index_negotiation_rounds_on_status"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "domain", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "courses_count", default: 0, null: false
    t.integer "users_count", default: 0, null: false
    t.uuid "license_id"
    t.boolean "direct_assignment_enabled"
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["domain"], name: "index_organizations_on_domain", unique: true
    t.index ["license_id"], name: "index_organizations_on_license_id"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "performance_scores", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.uuid "team_id", null: false
    t.uuid "user_id"
    t.decimal "settlement_quality_score", precision: 5, scale: 2
    t.decimal "legal_strategy_score", precision: 5, scale: 2
    t.decimal "collaboration_score", precision: 5, scale: 2
    t.decimal "efficiency_score", precision: 5, scale: 2
    t.decimal "speed_bonus", precision: 5, scale: 2
    t.decimal "creative_terms_score", precision: 5, scale: 2
    t.decimal "total_score", precision: 6, scale: 2, null: false
    t.jsonb "score_breakdown", default: {}, null: false
    t.datetime "scored_at", null: false
    t.string "score_type", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "instructor_adjustment"
    t.text "adjustment_reason"
    t.uuid "adjusted_by_id"
    t.datetime "adjusted_at"
    t.index ["adjusted_by_id"], name: "index_performance_scores_on_adjusted_by_id"
    t.index ["deleted_at"], name: "index_performance_scores_on_deleted_at"
    t.index ["score_type"], name: "index_performance_scores_on_score_type"
    t.index ["simulation_id", "team_id", "user_id"], name: "idx_on_simulation_id_team_id_user_id_9f822f0236", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["simulation_id", "team_id"], name: "index_performance_scores_on_simulation_id_and_team_id", unique: true, where: "(user_id IS NULL)"
    t.index ["simulation_id"], name: "index_performance_scores_on_simulation_id"
    t.index ["team_id"], name: "index_performance_scores_on_team_id"
    t.index ["total_score"], name: "index_performance_scores_on_total_score"
    t.index ["user_id"], name: "index_performance_scores_on_user_id"
  end

  create_table "personality_consistency_trackers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.string "personality_type", null: false
    t.jsonb "response_history", default: [], null: false
    t.integer "consistency_score", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id", "personality_type"], name: "index_personality_trackers_on_case_and_type"
    t.index ["case_id"], name: "index_personality_consistency_trackers_on_case_id"
    t.index ["consistency_score"], name: "index_personality_consistency_trackers_on_consistency_score"
    t.index ["deleted_at"], name: "index_personality_consistency_trackers_on_deleted_at"
    t.index ["personality_type"], name: "index_personality_consistency_trackers_on_personality_type"
  end

  create_table "settlement_offers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "negotiation_round_id", null: false
    t.uuid "team_id", null: false
    t.enum "offer_type", null: false, enum_type: "offer_type"
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.text "justification", null: false
    t.text "non_monetary_terms"
    t.uuid "submitted_by_id", null: false
    t.datetime "submitted_at", null: false
    t.decimal "quality_score", precision: 5, scale: 2
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "instructor_legal_reasoning_score"
    t.integer "instructor_factual_analysis_score"
    t.integer "instructor_strategic_thinking_score"
    t.integer "instructor_professionalism_score"
    t.integer "instructor_creativity_score"
    t.integer "instructor_quality_score"
    t.text "instructor_feedback"
    t.uuid "scored_by_id"
    t.datetime "scored_at"
    t.integer "final_quality_score"
    t.index ["deleted_at"], name: "index_settlement_offers_on_deleted_at"
    t.index ["negotiation_round_id", "team_id"], name: "index_settlement_offers_on_negotiation_round_id_and_team_id", unique: true
    t.index ["negotiation_round_id"], name: "index_settlement_offers_on_negotiation_round_id"
    t.index ["offer_type"], name: "index_settlement_offers_on_offer_type"
    t.index ["submitted_at"], name: "index_settlement_offers_on_submitted_at"
    t.index ["submitted_by_id"], name: "index_settlement_offers_on_submitted_by_id"
    t.index ["team_id"], name: "index_settlement_offers_on_team_id"
    t.check_constraint "final_quality_score >= 0 AND final_quality_score <= 125", name: "check_final_quality_score_range"
    t.check_constraint "instructor_creativity_score >= 0 AND instructor_creativity_score <= 25", name: "check_creativity_score_range"
    t.check_constraint "instructor_factual_analysis_score >= 0 AND instructor_factual_analysis_score <= 25", name: "check_factual_analysis_score_range"
    t.check_constraint "instructor_legal_reasoning_score >= 0 AND instructor_legal_reasoning_score <= 25", name: "check_legal_reasoning_score_range"
    t.check_constraint "instructor_professionalism_score >= 0 AND instructor_professionalism_score <= 25", name: "check_professionalism_score_range"
    t.check_constraint "instructor_quality_score >= 0 AND instructor_quality_score <= 125", name: "check_instructor_quality_score_range"
    t.check_constraint "instructor_strategic_thinking_score >= 0 AND instructor_strategic_thinking_score <= 25", name: "check_strategic_thinking_score_range"
  end

  create_table "simulation_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "simulation_id", null: false
    t.enum "event_type", null: false, enum_type: "event_type"
    t.jsonb "event_data", default: {}, null: false
    t.datetime "triggered_at", null: false
    t.text "impact_description", null: false
    t.jsonb "pressure_adjustment", default: {}, null: false
    t.integer "trigger_round", null: false
    t.boolean "automatic", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_simulation_events_on_deleted_at"
    t.index ["event_type"], name: "index_simulation_events_on_event_type"
    t.index ["simulation_id"], name: "index_simulation_events_on_simulation_id"
    t.index ["trigger_round"], name: "index_simulation_events_on_trigger_round"
    t.index ["triggered_at"], name: "index_simulation_events_on_triggered_at"
  end

  create_table "simulations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date"
    t.integer "total_rounds", default: 6, null: false
    t.integer "current_round", default: 1, null: false
    t.enum "status", default: "setup", null: false, enum_type: "simulation_status"
    t.decimal "plaintiff_min_acceptable", precision: 12, scale: 2, null: false
    t.decimal "plaintiff_ideal", precision: 12, scale: 2, null: false
    t.decimal "defendant_max_acceptable", precision: 12, scale: 2, null: false
    t.decimal "defendant_ideal", precision: 12, scale: 2, null: false
    t.enum "pressure_escalation_rate", default: "moderate", null: false, enum_type: "pressure_escalation"
    t.jsonb "simulation_config", default: {}, null: false
    t.boolean "auto_events_enabled", default: true, null: false
    t.boolean "argument_quality_required", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_simulations_on_case_id"
    t.index ["current_round"], name: "index_simulations_on_current_round"
    t.index ["deleted_at"], name: "index_simulations_on_deleted_at"
    t.index ["start_date"], name: "index_simulations_on_start_date"
    t.index ["status"], name: "index_simulations_on_status"
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
    t.uuid "course_id"
    t.integer "team_members_count", default: 0, null: false
    t.index ["course_id"], name: "index_teams_on_course_id"
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["name", "owner_id"], name: "index_teams_on_name_and_owner_id", unique: true
    t.index ["owner_id"], name: "index_teams_on_owner_id"
  end

  create_table "terms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "term_name", null: false
    t.integer "academic_year", null: false
    t.string "slug", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.text "description"
    t.uuid "organization_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year"], name: "index_terms_on_academic_year"
    t.index ["active"], name: "index_terms_on_active"
    t.index ["deleted_at"], name: "index_terms_on_deleted_at"
    t.index ["organization_id", "academic_year", "active"], name: "index_terms_on_organization_id_and_academic_year_and_active"
    t.index ["organization_id", "slug"], name: "index_terms_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_terms_on_organization_id"
    t.index ["start_date", "end_date"], name: "index_terms_on_start_date_and_end_date"
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
    t.uuid "organization_id"
    t.boolean "org_admin", default: false, null: false
    t.text "roles", default: [], array: true
    t.index "lower((first_name)::text), lower((last_name)::text)", name: "index_users_on_lower_names"
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id", "org_admin"], name: "index_users_on_organization_id_and_org_admin", where: "(org_admin = true)"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["roles"], name: "index_users_on_roles", using: :gin
  end

  add_foreign_key "arbitration_outcomes", "simulations"
  add_foreign_key "case_events", "cases", on_delete: :cascade
  add_foreign_key "case_events", "users"
  add_foreign_key "case_teams", "cases"
  add_foreign_key "case_teams", "teams"
  add_foreign_key "cases", "courses"
  add_foreign_key "cases", "users", column: "created_by_id"
  add_foreign_key "cases", "users", column: "updated_by_id"
  add_foreign_key "client_feedbacks", "settlement_offers"
  add_foreign_key "client_feedbacks", "simulations"
  add_foreign_key "client_feedbacks", "teams"
  add_foreign_key "course_enrollments", "courses"
  add_foreign_key "course_enrollments", "users"
  add_foreign_key "course_invitations", "courses"
  add_foreign_key "courses", "organizations"
  add_foreign_key "courses", "terms"
  add_foreign_key "courses", "users", column: "instructor_id"
  add_foreign_key "documents", "users", column: "created_by_id"
  add_foreign_key "evidence_releases", "documents"
  add_foreign_key "evidence_releases", "simulations"
  add_foreign_key "evidence_releases", "teams", column: "requesting_team_id"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "negotiation_rounds", "simulations"
  add_foreign_key "organizations", "licenses"
  add_foreign_key "performance_scores", "simulations"
  add_foreign_key "performance_scores", "teams"
  add_foreign_key "performance_scores", "users"
  add_foreign_key "performance_scores", "users", column: "adjusted_by_id"
  add_foreign_key "personality_consistency_trackers", "cases"
  add_foreign_key "settlement_offers", "negotiation_rounds"
  add_foreign_key "settlement_offers", "teams"
  add_foreign_key "settlement_offers", "users", column: "scored_by_id"
  add_foreign_key "settlement_offers", "users", column: "submitted_by_id"
  add_foreign_key "simulation_events", "simulations"
  add_foreign_key "simulations", "cases"
  add_foreign_key "team_members", "teams", on_delete: :cascade
  add_foreign_key "team_members", "users"
  add_foreign_key "teams", "courses"
  add_foreign_key "teams", "users", column: "owner_id"
  add_foreign_key "terms", "organizations"
  add_foreign_key "users", "organizations"
end
