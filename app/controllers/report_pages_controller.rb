class ReportPagesController < ApplicationController
  before_action :authenticate_user!

  def subsection
    @section = SidebarSection.active.find_by!(slug: params[:section_slug])

    @subsection = @section.sidebar_subsections.active.find_by!(slug: params[:subsection_slug])

    @report_pages = ReportPage.active
                              .where(sidebar_section: @section, sidebar_subsection: @subsection)
                              .where(visible_for: ["shared", current_user.user_type])
                              .order(:position, :title)
  end
end