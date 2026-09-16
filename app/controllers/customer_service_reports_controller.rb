class CustomerServiceReportsController < ApplicationController
  before_action :authenticate_user!

  def show
    @dashboard = CustomerService::DashboardData.new(
      view: params[:view]
    ).call
  end
end
