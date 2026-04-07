class ReportPagesController < ApplicationController
  before_action :authenticate_user!

  def show
    @sidebar_section = SidebarSection.find_by!(slug: params[:slug])

    @report_pages = @sidebar_section.report_pages
                                    .where(sidebar_subsection_id: nil)
                                    .active
                                    .ordered
                                    .select { |report| report.visible_to?(current_user) }
  end

  def subsection
    @sidebar_section = SidebarSection.find_by!(slug: params[:section_slug])
    @sidebar_subsection = @sidebar_section.sidebar_subsections.find_by!(slug: params[:subsection_slug])

    @report_pages = @sidebar_subsection.report_pages
                                       .active
                                       .ordered
                                       .select { |report| report.visible_to?(current_user) }

    render :show
  end
end