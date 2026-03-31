class Admin::SidebarSectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_sidebar_section, only: [:show, :edit, :update, :destroy]

  def index
    @sidebar_sections = SidebarSection.order(:position, :title)
  end

  def show
  end

  def new
    @sidebar_section = SidebarSection.new
  end

  def create
    @sidebar_section = SidebarSection.new(sidebar_section_params)

    if @sidebar_section.save
      redirect_to admin_sidebar_section_path(@sidebar_section), notice: "Seção criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sidebar_section.update(sidebar_section_params)
      redirect_to admin_sidebar_section_path(@sidebar_section), notice: "Seção atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sidebar_section.destroy
    redirect_to admin_sidebar_sections_path, notice: "Seção removida com sucesso."
  end

  private

  def ensure_admin!
    redirect_to dashboard_path, alert: "Acesso não autorizado." unless current_user.admin?
  end

  def set_sidebar_section
    @sidebar_section = SidebarSection.find(params[:id])
  end

  def sidebar_section_params
    params.require(:sidebar_section).permit(
      :title,
      :slug,
      :position,
      :active
    )
  end
end