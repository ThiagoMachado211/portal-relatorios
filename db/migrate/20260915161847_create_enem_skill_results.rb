class CreateEnemSkillResults < ActiveRecord::Migration[8.0]
  def change
    create_table :enem_skill_results do |t|
      t.integer :year, null: false
      t.string :uf, null: false
      t.string :dependency, null: false
      t.string :area, null: false

      t.integer :competency_code
      t.integer :skill_code, null: false
      t.string :skill_status, null: false

      t.integer :item_count
      t.integer :participant_count
      t.integer :response_count
      t.integer :correct_count

      t.decimal :correct_rate,
                precision: 12,
                scale: 10

      t.timestamps
    end

    add_index :enem_skill_results,
              [:year, :uf, :dependency, :area, :skill_code],
              unique: true,
              name: "idx_enem_skill_results_unique"

    add_index :enem_skill_results,
              [:area, :skill_code, :year],
              name: "idx_enem_skill_results_history"

    add_index :enem_skill_results,
              [:year, :uf, :dependency],
              name: "idx_enem_skill_results_filters"
  end
end