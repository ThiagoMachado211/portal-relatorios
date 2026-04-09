ActiveRecord::Schema[8.1].define(version: 2026_04_08_114337) do
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
  add_foreign_key "report_pages", "sidebar_sections"
  add_foreign_key "report_pages", "sidebar_subsections"
  add_foreign_key "sidebar_subsections", "sidebar_sections"
end