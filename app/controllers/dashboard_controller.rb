class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @report_pages = ReportPage.where(active: true)
  end
end