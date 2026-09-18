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

ActiveRecord::Schema[8.1].define(version: 2026_09_18_120830) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_chat_conversations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_chat_conversations_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_conversation_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_conversation_id", "created_at"], name: "index_chat_messages_on_chat_conversation_id_and_created_at"
    t.index ["chat_conversation_id"], name: "index_chat_messages_on_chat_conversation_id"
  end

  create_table "customer_service_monthly_results", force: :cascade do |t|
    t.integer "avg_first_response_seconds"
    t.integer "avg_resolution_seconds"
    t.integer "avg_response_seconds"
    t.integer "bad_classifications_count", default: 0, null: false
    t.integer "closed_tickets_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "fcr_tickets_count", default: 0, null: false
    t.integer "first_responses_count", default: 0, null: false
    t.integer "good_classifications_count", default: 0, null: false
    t.integer "month", null: false
    t.integer "ok_classifications_count", default: 0, null: false
    t.integer "output_count", default: 0, null: false
    t.integer "reopened_tickets_count", default: 0, null: false
    t.integer "responses_count", default: 0, null: false
    t.string "source_filename", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year", "month"], name: "idx_customer_service_monthly_results_unique", unique: true
  end

  create_table "enem_skill_distributions", force: :cascade do |t|
    t.string "area", null: false
    t.integer "competency_code"
    t.datetime "created_at", null: false
    t.decimal "english_question_count"
    t.decimal "english_question_percentage", precision: 10, scale: 8
    t.decimal "question_count"
    t.decimal "question_percentage", precision: 10, scale: 8
    t.integer "skill_code", null: false
    t.string "skill_status", null: false
    t.decimal "spanish_question_count"
    t.decimal "spanish_question_percentage", precision: 10, scale: 8
    t.integer "total_area_questions", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["area", "skill_code", "year"], name: "idx_enem_skill_dist_history"
    t.index ["year", "area", "skill_code"], name: "idx_enem_skill_dist_year_area_skill", unique: true
  end

  create_table "enem_skill_results", force: :cascade do |t|
    t.string "area", null: false
    t.integer "competency_code"
    t.integer "correct_count"
    t.decimal "correct_rate", precision: 12, scale: 10
    t.datetime "created_at", null: false
    t.string "dependency", null: false
    t.integer "item_count"
    t.integer "participant_count"
    t.integer "response_count"
    t.integer "skill_code", null: false
    t.string "skill_status", null: false
    t.string "uf", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["area", "skill_code", "year"], name: "idx_enem_skill_results_history"
    t.index ["year", "uf", "dependency", "area", "skill_code"], name: "idx_enem_skill_results_unique", unique: true
    t.index ["year", "uf", "dependency"], name: "idx_enem_skill_results_filters"
  end

  create_table "enem_skills", force: :cascade do |t|
    t.string "area", null: false
    t.string "area_name", null: false
    t.integer "competency_code", null: false
    t.text "competency_description", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "skill_code", null: false
    t.text "skill_description", null: false
    t.datetime "updated_at", null: false
    t.index ["area", "skill_code"], name: "idx_enem_skills_area_skill", unique: true
  end

  create_table "enem_state_results", force: :cascade do |t|
    t.string "administrative_dependency", null: false
    t.datetime "created_at", null: false
    t.decimal "essay_average", precision: 8, scale: 2
    t.decimal "essay_competency_1_average", precision: 7, scale: 2
    t.decimal "essay_competency_2_average", precision: 7, scale: 2
    t.decimal "essay_competency_3_average", precision: 7, scale: 2
    t.decimal "essay_competency_4_average", precision: 7, scale: 2
    t.decimal "essay_competency_5_average", precision: 7, scale: 2
    t.bigint "essays_annulled_count", default: 0, null: false
    t.decimal "essays_annulled_pct", precision: 7, scale: 2
    t.bigint "essays_blank_count", default: 0, null: false
    t.decimal "essays_blank_pct", precision: 7, scale: 2
    t.bigint "essays_count", default: 0, null: false
    t.bigint "essays_disconnected_part_count", default: 0, null: false
    t.decimal "essays_disconnected_part_pct", precision: 7, scale: 2
    t.bigint "essays_human_rights_violation_count", default: 0, null: false
    t.decimal "essays_human_rights_violation_pct", precision: 7, scale: 2
    t.bigint "essays_insufficient_text_count", default: 0, null: false
    t.decimal "essays_insufficient_text_pct", precision: 7, scale: 2
    t.bigint "essays_motivating_text_copy_count", default: 0, null: false
    t.decimal "essays_motivating_text_copy_pct", precision: 7, scale: 2
    t.bigint "essays_off_topic_count", default: 0, null: false
    t.decimal "essays_off_topic_pct", precision: 7, scale: 2
    t.bigint "essays_ok_count", default: 0, null: false
    t.decimal "essays_ok_pct", precision: 7, scale: 2
    t.bigint "essays_wrong_text_type_count", default: 0, null: false
    t.decimal "essays_wrong_text_type_pct", precision: 7, scale: 2
    t.decimal "general_average", precision: 8, scale: 2
    t.decimal "human_sciences_average", precision: 8, scale: 2
    t.decimal "languages_average", precision: 8, scale: 2
    t.decimal "mathematics_average", precision: 8, scale: 2
    t.decimal "natural_sciences_average", precision: 8, scale: 2
    t.bigint "participants_both_days_count", default: 0, null: false
    t.bigint "participants_day1_count", default: 0, null: false
    t.bigint "participants_day2_count", default: 0, null: false
    t.decimal "participation_both_days_pct", precision: 7, scale: 2
    t.decimal "participation_day1_pct", precision: 7, scale: 2
    t.decimal "participation_day2_pct", precision: 7, scale: 2
    t.bigint "registered_count", default: 0, null: false
    t.string "state_code", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["administrative_dependency"], name: "index_enem_state_results_on_administrative_dependency"
    t.index ["state_code"], name: "index_enem_state_results_on_state_code"
    t.index ["year", "state_code", "administrative_dependency"], name: "idx_enem_state_results_unique", unique: true
    t.index ["year"], name: "index_enem_state_results_on_year"
  end

  create_table "long_trips", force: :cascade do |t|
    t.boolean "canceled"
    t.datetime "created_at", null: false
    t.string "destination_city"
    t.string "destination_state"
    t.string "destination_terminal"
    t.decimal "extra_fees_brl"
    t.decimal "mileage"
    t.text "non_compliance_reason"
    t.string "origin_city"
    t.string "origin_state"
    t.string "origin_terminal"
    t.boolean "policy_compliant"
    t.date "purchase_date"
    t.decimal "purchase_value_brl"
    t.decimal "purchase_value_points"
    t.decimal "refund_value_brl"
    t.decimal "refund_value_points"
    t.string "transport_company"
    t.string "transport_mode"
    t.date "travel_date"
    t.string "travel_reason"
    t.integer "travel_request_id"
    t.string "traveler_name"
    t.string "traveler_sector"
    t.datetime "updated_at", null: false
  end

  create_table "report_pages", force: :cascade do |t|
    t.boolean "active"
    t.integer "content_type", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.text "embed_url"
    t.integer "position", default: 0
    t.integer "sidebar_section_id"
    t.bigint "sidebar_subsection_id"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "visible_for", default: 2
    t.index ["sidebar_section_id"], name: "index_report_pages_on_sidebar_section_id"
    t.index ["sidebar_subsection_id"], name: "index_report_pages_on_sidebar_subsection_id"
  end

  create_table "sidebar_sections", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "sidebar_subsections", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "sidebar_section_id", null: false
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["sidebar_section_id"], name: "index_sidebar_subsections_on_sidebar_section_id"
  end

  create_table "travel_accommodations", force: :cascade do |t|
    t.decimal "average_daily_rate_brl", precision: 14, scale: 2
    t.date "check_in_date"
    t.date "check_out_date"
    t.datetime "created_at", null: false
    t.text "daily_rates_text"
    t.string "hotel"
    t.date "purchase_date"
    t.integer "stay_duration_days"
    t.decimal "total_stay_value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "travel_request_id", null: false
    t.string "traveler_name"
    t.datetime "updated_at", null: false
    t.index ["check_in_date"], name: "index_travel_accommodations_on_check_in_date"
    t.index ["hotel"], name: "index_travel_accommodations_on_hotel"
    t.index ["travel_request_id"], name: "index_travel_accommodations_on_travel_request_id"
  end

  create_table "travel_metrics", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "metric_type"
    t.integer "month"
    t.text "notes"
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "value"
    t.integer "year"
    t.index ["user_id"], name: "index_travel_metrics_on_user_id"
  end

  create_table "travel_summaries", force: :cascade do |t|
    t.decimal "accommodation_value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.integer "duration_days"
    t.decimal "long_segments_value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.date "outbound_date"
    t.date "return_date"
    t.decimal "short_segments_value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "total_value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "total_value_points", precision: 16, scale: 2, default: "0.0", null: false
    t.integer "travel_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["outbound_date"], name: "index_travel_summaries_on_outbound_date"
    t.index ["travel_request_id"], name: "index_travel_summaries_on_travel_request_id", unique: true
  end

  create_table "travel_transfers", force: :cascade do |t|
    t.string "company"
    t.datetime "created_at", null: false
    t.string "destination"
    t.decimal "estimated_mileage", precision: 12, scale: 2, default: "0.0", null: false
    t.string "origin"
    t.date "travel_date"
    t.string "travel_reason"
    t.integer "travel_request_id", null: false
    t.string "traveler_name"
    t.string "traveler_sector"
    t.datetime "updated_at", null: false
    t.decimal "value_brl", precision: 14, scale: 2, default: "0.0", null: false
    t.index ["travel_date"], name: "index_travel_transfers_on_travel_date"
    t.index ["travel_request_id"], name: "index_travel_transfers_on_travel_request_id"
    t.index ["traveler_sector"], name: "index_travel_transfers_on_traveler_sector"
  end

  create_table "users", force: :cascade do |t|
    t.integer "access_count", default: 0, null: false
    t.boolean "active"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_access_at"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.integer "user_type"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_conversations", "users"
  add_foreign_key "chat_messages", "chat_conversations"
  add_foreign_key "report_pages", "sidebar_sections"
  add_foreign_key "report_pages", "sidebar_subsections"
  add_foreign_key "sidebar_subsections", "sidebar_sections"
  add_foreign_key "travel_metrics", "users"
end
