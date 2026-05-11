class AddAccessTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_access_at, :datetime
    add_column :users, :access_count, :integer, default: 0, null: false
  end
end
