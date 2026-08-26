class ReportPagesController < ApplicationController
  before_action :authenticate_user!

  def subsection
    @section = SidebarSection.find_by!(
      slug: params[:section_slug]
    )

    @subsection = @section.sidebar_subsections.find_by!(
      slug: params[:subsection_slug]
    )

    @report_pages = ReportPage.where(
      sidebar_section: @section,
      sidebar_subsection: @subsection,
      active: true
    ).order(:position)

    apply_visibility_filter!

    load_special_content
  end

  private

  def apply_visibility_filter!
    return if current_user.admin?

    allowed_visibility =
      case current_user.user_type
      when "manager"
        %w[manager shared]
      else
        %w[client shared]
      end

    @report_pages =
      @report_pages.where(
        visible_for: allowed_visibility
      )
  end

  def load_special_content
    if @section.slug == "calendarios" &&
       @subsection.slug == "mg"

      @calendar_items = CalendarData.mg_items
    end
  end
end