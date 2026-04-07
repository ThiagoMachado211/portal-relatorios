class AddSidebarSubsectionToReportPages < ActiveRecord::Migration[8.0]
  def change
    add_reference :report_pages, :sidebar_subsection, foreign_key: true
  end
end