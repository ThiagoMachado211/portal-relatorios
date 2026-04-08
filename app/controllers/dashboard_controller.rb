class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout false

  def index
    @last_access_at = current_user.last_access_at
    @access_count = current_user.access_count || 0

    visible_reports = ReportPage.active.select { |report| report.visible_to?(current_user) }
    @available_content_count = visible_reports.count
    @last_data_update = visible_reports.map(&:updated_at).compact.max
  end
end