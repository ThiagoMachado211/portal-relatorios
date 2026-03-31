class CreateReportPages < ActiveRecord::Migration[8.1]
  def change
    create_table :report_pages do |t|
      t.string :title
      t.string :slug
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end
end
