class EnemSkillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @dashboard = Enem::SkillsDashboardData.new(
      view: params[:view],
      year: params[:year],
      area: params[:area],
      language: params[:language],
      skill_code: params[:skill_code],
      uf: params[:uf],
      dependency: params[:dependency]
    ).call
  end
end
