class AddFieldsToReportPages < ActiveRecord::Migration[8.0]
  def change
    add_column :report_pages, :content_type, :integer, default: 0
    add_column :report_pages, :visible_for, :integer, default: 2
    add_column :report_pages, :embed_url, :text
    add_column :report_pages, :position, :integer, default: 0
  end
end