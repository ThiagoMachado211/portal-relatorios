class CreateEnemSkillDistributions < ActiveRecord::Migration[8.0]
  def change
    create_table :enem_skill_distributions do |t|
      t.integer :year, null: false
      t.string :area, null: false

      t.integer :competency_code
      t.integer :skill_code, null: false
      t.string :skill_status, null: false

      t.decimal :question_count
      t.decimal :question_percentage,
                precision: 10,
                scale: 8

      t.decimal :english_question_count
      t.decimal :english_question_percentage,
                precision: 10,
                scale: 8

      t.decimal :spanish_question_count
      t.decimal :spanish_question_percentage,
                precision: 10,
                scale: 8

      t.integer :total_area_questions, null: false

      t.timestamps
    end

    add_index :enem_skill_distributions,
              [:year, :area, :skill_code],
              unique: true,
              name: "idx_enem_skill_dist_year_area_skill"

    add_index :enem_skill_distributions,
              [:area, :skill_code, :year],
              name: "idx_enem_skill_dist_history"
  end
end