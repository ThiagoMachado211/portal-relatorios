class CreateTravelSupplementalData < ActiveRecord::Migration[8.1]
  def change
    create_table :travel_summaries do |t|
      t.integer :travel_request_id, null: false
      t.date :outbound_date
      t.date :return_date
      t.integer :duration_days
      t.decimal :long_segments_value_brl, precision: 14, scale: 2, default: 0, null: false
      t.decimal :short_segments_value_brl, precision: 14, scale: 2, default: 0, null: false
      t.decimal :accommodation_value_brl, precision: 14, scale: 2, default: 0, null: false
      t.decimal :total_value_brl, precision: 14, scale: 2, default: 0, null: false
      t.decimal :total_value_points, precision: 16, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :travel_summaries, :travel_request_id, unique: true
    add_index :travel_summaries, :outbound_date

    create_table :travel_accommodations do |t|
      t.integer :travel_request_id, null: false
      t.string :traveler_name
      t.string :hotel
      t.date :purchase_date
      t.date :check_in_date
      t.date :check_out_date
      t.integer :stay_duration_days
      t.text :daily_rates_text
      t.decimal :average_daily_rate_brl, precision: 14, scale: 2
      t.decimal :total_stay_value_brl, precision: 14, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :travel_accommodations, :travel_request_id
    add_index :travel_accommodations, :check_in_date
    add_index :travel_accommodations, :hotel

    create_table :travel_transfers do |t|
      t.integer :travel_request_id, null: false
      t.string :traveler_name
      t.string :traveler_sector
      t.string :travel_reason
      t.string :company
      t.string :origin
      t.string :destination
      t.decimal :estimated_mileage, precision: 12, scale: 2, default: 0, null: false
      t.date :travel_date
      t.decimal :value_brl, precision: 14, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :travel_transfers, :travel_request_id
    add_index :travel_transfers, :travel_date
    add_index :travel_transfers, :traveler_sector
  end
end
