class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    redirect_to dashboard_path, alert: "Acesso não autorizado." unless current_user&.admin?
  end
end