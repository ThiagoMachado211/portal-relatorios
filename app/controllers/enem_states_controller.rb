class EnemStatesController < ApplicationController
  before_action :authenticate_user!

  def show
    @dashboard = Enem::StatesDashboardData.new(
      year: params[:year],
      state_code: params[:state_code],
      dependency: params[:dependency],
      view: params[:view],
      evolution_metric: params[:evolution_metric],
      ranking_metric: params[:ranking_metric]
    ).call
  end
end
