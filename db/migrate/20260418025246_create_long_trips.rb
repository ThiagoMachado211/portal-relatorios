class CreateLongTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :long_trips do |t|
      t.integer :travel_request_id
      t.string :traveler_name
      t.string :traveler_sector
      t.string :travel_reason
      t.date :purchase_date
      t.date :travel_date
      t.string :transport_mode
      t.string :origin_city
      t.string :origin_state
      t.string :origin_terminal
      t.string :destination_city
      t.string :destination_state
      t.string :destination_terminal
      t.string :transport_company
      t.decimal :mileage
      t.boolean :policy_compliant
      t.text :non_compliance_reason
      t.boolean :canceled
      t.decimal :purchase_value_brl
      t.decimal :purchase_value_points
      t.decimal :extra_fees_brl
      t.decimal :refund_value_brl
      t.decimal :refund_value_points

      t.timestamps
    end
  end
end
