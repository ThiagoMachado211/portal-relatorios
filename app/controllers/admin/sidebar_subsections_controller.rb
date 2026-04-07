class Admin::SidebarSubsectionsController < Admin::BaseController
  before_action :set_sidebar_subsection, only: [:show, :edit, :update, :destroy]
  before_action :load_sidebar_sections, only: [:new, :create, :edit, :update]

  def index
    @sidebar_subsections = SidebarSubsection.includes(:sidebar_section).ordered
  end

  def show
  end

  def new
    @sidebar_subsection = SidebarSubsection.new
  end

  def create
    @sidebar_subsection = SidebarSubsection.new(sidebar_subsection_params)

    if @sidebar_subsection.save
      redirect_to admin_sidebar_subsections_path, notice: "Subseção criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sidebar_subsection.update(sidebar_subsection_params)
      redirect_to admin_sidebar_subsections_path, notice: "Subseção atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sidebar_subsection.destroy
    redirect_to admin_sidebar_subsections_path, notice: "Subseção removida com sucesso."
  end

  def by_section
    subsections = SidebarSubsection
                    .where(sidebar_section_id: params[:sidebar_section_id])
                    .active
                    .ordered
                    .select(:id, :title)

    render json: subsections
  end

  private

  def set_sidebar_subsection
    @sidebar_subsection = SidebarSubsection.find(params[:id])
  end

  def load_sidebar_sections
    @sidebar_sections = SidebarSection.active.ordered
  end

  def sidebar_subsection_params
    params.require(:sidebar_subsection).permit(:sidebar_section_id, :title, :slug, :position, :active)
  end
end