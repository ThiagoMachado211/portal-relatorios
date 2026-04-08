class DashboardController < ApplicationController
  before_action :authenticate_user!

  layout false

  def index
    render plain: "dashboard ok"
  end
end