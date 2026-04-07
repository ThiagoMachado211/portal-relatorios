class Admin::ReportPagesController < Admin::BaseController
  before_action :set_report_page, only: [:show, :edit, :update, :destroy]
  before_action :load_sidebar_data, only: [:new, :create, :edit, :update]

  def index
    @report_pages = ReportPage.includes(:sidebar_section, :sidebar_subsection).ordered
  end

  def show
  end

  def new
    @report_page = ReportPage.new
  end

  def create
    @report_page = ReportPage.new(report_page_params)

    if @report_page.save
      redirect_to admin_report_pages_path, notice: "Relatório criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @report_page.update(report_page_params)
      redirect_to admin_report_pages_path, notice: "Relatório atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @report_page.destroy
    redirect_to admin_report_pages_path, notice: "Relatório removido com sucesso."
  end

  private

  def set_report_page
    @report_page = ReportPage.find(params[:id])
  end

  def load_sidebar_data
    @sidebar_sections = SidebarSection.active.ordered
    @sidebar_subsections = SidebarSubsection.active.ordered
  end

  def report_page_params
    params.require(:report_page).permit(
      :title,
      :slug,
      :description,
      :sidebar_section_id,
      :sidebar_subsection_id,
      :content_type,
      :visible_for,
      :embed_url,
      :position,
      :active
    )
  end
end