class ReportPagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @report_pages = ReportPage.where(active: true)
  end

  def show
    @report_page = ReportPage.find_by!(slug: params[:id])
  end
end