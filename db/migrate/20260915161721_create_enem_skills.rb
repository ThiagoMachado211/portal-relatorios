class CreateEnemSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :enem_skills do |t|
      t.string :area, null: false
      t.string :name, null: false
      t.string :area_name, null: false

      t.integer :competency_code, null: false
      t.text :competency_description, null: false

      t.integer :skill_code, null: false
      t.text :skill_description, null: false

      t.timestamps
    end

    add_index :enem_skills,
              [:area, :skill_code],
              unique: true,
              name: "idx_enem_skills_area_skill"
  end
end