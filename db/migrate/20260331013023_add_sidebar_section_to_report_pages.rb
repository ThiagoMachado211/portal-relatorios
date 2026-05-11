class AddSidebarSectionToReportPages < ActiveRecord::Migration[8.1]
  def change
    add_reference :report_pages, :sidebar_section, null: true, foreign_key: true
  end
end
