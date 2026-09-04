class CreateEnemStateResults < ActiveRecord::Migration[8.1]
  def change
    create_table :enem_state_results do |t|
      t.integer :year, null: false
      t.string :state_code, null: false
      t.string :administrative_dependency, null: false

      t.bigint :registered_count, null: false, default: 0
      t.bigint :participants_day1_count, null: false, default: 0
      t.bigint :participants_day2_count, null: false, default: 0
      t.bigint :participants_both_days_count, null: false, default: 0

      t.decimal :participation_day1_pct, precision: 7, scale: 2
      t.decimal :participation_day2_pct, precision: 7, scale: 2
      t.decimal :participation_both_days_pct, precision: 7, scale: 2

      t.decimal :human_sciences_average, precision: 8, scale: 2
      t.decimal :languages_average, precision: 8, scale: 2
      t.decimal :natural_sciences_average, precision: 8, scale: 2
      t.decimal :mathematics_average, precision: 8, scale: 2
      t.decimal :essay_average, precision: 8, scale: 2
      t.decimal :general_average, precision: 8, scale: 2

      t.decimal :essay_competency_1_average, precision: 7, scale: 2
      t.decimal :essay_competency_2_average, precision: 7, scale: 2
      t.decimal :essay_competency_3_average, precision: 7, scale: 2
      t.decimal :essay_competency_4_average, precision: 7, scale: 2
      t.decimal :essay_competency_5_average, precision: 7, scale: 2

      t.bigint :essays_count, null: false, default: 0

      t.bigint :essays_ok_count, null: false, default: 0
      t.bigint :essays_annulled_count, null: false, default: 0
      t.bigint :essays_motivating_text_copy_count, null: false, default: 0
      t.bigint :essays_blank_count, null: false, default: 0
      t.bigint :essays_human_rights_violation_count, null: false, default: 0
      t.bigint :essays_off_topic_count, null: false, default: 0
      t.bigint :essays_wrong_text_type_count, null: false, default: 0
      t.bigint :essays_insufficient_text_count, null: false, default: 0
      t.bigint :essays_disconnected_part_count, null: false, default: 0

      t.decimal :essays_ok_pct, precision: 7, scale: 2
      t.decimal :essays_annulled_pct, precision: 7, scale: 2
      t.decimal :essays_motivating_text_copy_pct, precision: 7, scale: 2
      t.decimal :essays_blank_pct, precision: 7, scale: 2
      t.decimal :essays_human_rights_violation_pct, precision: 7, scale: 2
      t.decimal :essays_off_topic_pct, precision: 7, scale: 2
      t.decimal :essays_wrong_text_type_pct, precision: 7, scale: 2
      t.decimal :essays_insufficient_text_pct, precision: 7, scale: 2
      t.decimal :essays_disconnected_part_pct, precision: 7, scale: 2

      t.timestamps
    end

    add_index :enem_state_results,
              [:year, :state_code, :administrative_dependency],
              unique: true,
              name: "idx_enem_state_results_unique"

    add_index :enem_state_results, :year
    add_index :enem_state_results, :state_code
    add_index :enem_state_results, :administrative_dependency
  end
end
