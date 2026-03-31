class CreateSidebarSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sidebar_sections do |t|
      t.string :title
      t.string :slug
      t.integer :position
      t.boolean :active

      t.timestamps
    end
  end
end
