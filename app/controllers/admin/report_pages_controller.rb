class Admin::ReportPagesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_report_page, only: [:show, :edit, :update, :destroy]

  def index
    @report_pages = ReportPage.order(:title)
  end

  def show
  end

  def new
    @report_page = ReportPage.new
  end

  def create
    @report_page = ReportPage.new(report_page_params)

    if @report_page.save
      redirect_to admin_report_page_path(@report_page), notice: "Página criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @report_page.update(report_page_params)
      redirect_to admin_report_page_path(@report_page), notice: "Página atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @report_page.destroy
    redirect_to admin_report_pages_path, notice: "Página removida com sucesso."
  end

  private

  def ensure_admin!
    redirect_to dashboard_path, alert: "Acesso não autorizado." unless current_user.admin?
  end

  def set_report_page
    @report_page = ReportPage.find(params[:id])
  end

  def report_page_params
    params.require(:report_page).permit(
      :title,
      :slug,
      :description,
      :active,
      :internal_file,
      :external_file,
      :sidebar_section_id
    )
  end
end