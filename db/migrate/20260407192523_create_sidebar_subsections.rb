class CreateSidebarSubsections < ActiveRecord::Migration[8.1]
  def change
    create_table :sidebar_subsections do |t|
      t.references :sidebar_section, null: false, foreign_key: true
      t.string :title
      t.string :slug
      t.integer :position
      t.boolean :active

      t.timestamps
    end
  end
end
