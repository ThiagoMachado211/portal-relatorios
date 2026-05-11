class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @last_access_at =
      if current_user.respond_to?(:last_access_at)
        current_user.last_access_at
      else
        nil
      end

    @access_count =
      if current_user.respond_to?(:access_count)
        current_user.access_count || 0
      else
        0
      end

    reports =
      if ReportPage.respond_to?(:active)
        ReportPage.active.to_a
      else
        ReportPage.all.to_a
      end

    visible_reports = reports.select do |report|
      begin
        report.visible_to?(current_user)
      rescue StandardError
        false
      end
    end

    @available_content_count = visible_reports.count
    @last_data_update = visible_reports.map(&:updated_at).compact.max
  end
end