class CreateCustomerServiceMonthlyResults < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_service_monthly_results do |t|
      t.integer :year, null: false
      t.integer :month, null: false

      t.integer :output_count, null: false, default: 0
      t.integer :responses_count, null: false, default: 0
      t.integer :first_responses_count, null: false, default: 0
      t.integer :fcr_tickets_count, null: false, default: 0
      t.integer :closed_tickets_count, null: false, default: 0
      t.integer :reopened_tickets_count, null: false, default: 0

      t.integer :avg_first_response_seconds
      t.integer :avg_response_seconds
      t.integer :avg_resolution_seconds

      t.string :source_filename, null: false

      t.timestamps
    end

    add_index :customer_service_monthly_results,
              [:year, :month],
              unique: true,
              name: "idx_customer_service_monthly_results_unique"
  end
end
