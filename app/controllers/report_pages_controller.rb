class ReportPagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sidebar_section

  def show
    @report_pages = @sidebar_section.report_pages
                                    .active
                                    .ordered
                                    .select { |report| report.visible_to?(current_user) }
  end

  private

  def set_sidebar_section
    @sidebar_section = SidebarSection.find_by!(slug: params[:slug])
  end
end