class CreateTravelMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :travel_metrics do |t|
      t.string :category
      t.string :metric_type
      t.string :state
      t.integer :month
      t.integer :year
      t.decimal :value
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
