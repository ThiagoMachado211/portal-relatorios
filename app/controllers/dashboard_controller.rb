class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @available_reports = ReportPage.active.select { |report| report.visible_to?(current_user) }

    @available_content_count = @available_reports.count

    @last_data_update =
      if @available_reports.any?
        @available_reports.map(&:updated_at).compact.max
      end

    @last_access_at = current_user.last_access_at
    @access_count = current_user.access_count
  end
end