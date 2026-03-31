class SidebarSectionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @sidebar_sections = SidebarSection.where(active: true).order(:position, :title)
    @sidebar_section = SidebarSection.find_by!(slug: params[:id])
    @report_pages = @sidebar_section.report_pages.where(active: true).order(:title)
  end
end