class AddClassificationsToCustomerServiceMonthlyResults < ActiveRecord::Migration[8.1]
  def change
    add_column :customer_service_monthly_results, :ok_classifications_count, :integer, null: false, default: 0
    add_column :customer_service_monthly_results, :bad_classifications_count, :integer, null: false, default: 0
    add_column :customer_service_monthly_results, :good_classifications_count, :integer, null: false, default: 0
  end
end
