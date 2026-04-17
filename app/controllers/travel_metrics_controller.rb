class TravelMetricsController < ApplicationController
  before_action :authenticate_user!

  def index
    @travel_metrics =
      if current_user.admin?
        TravelMetric.includes(:user).order(year: :desc, month: :desc, created_at: :desc)
      else
        current_user.travel_metrics.order(year: :desc, month: :desc, created_at: :desc)
      end
  end

  def new
    @travel_metric = current_user.travel_metrics.build
  end

  def create
    @travel_metric = current_user.travel_metrics.build(travel_metric_params)

    if @travel_metric.save
      redirect_to travel_metrics_path, notice: "Métrica cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    @category = params[:category].presence || "Passagens Aéreas"
    @metric_type = params[:metric_type].presence || "Quantidade"
    @year = params[:year].presence&.to_i || Date.current.year

    base_scope = current_user.admin? ? TravelMetric.all : current_user.travel_metrics

    scoped = base_scope.where(
      category: @category,
      metric_type: @metric_type,
      year: @year
    )

    @total_value = scoped.sum(:value)

    monthly_hash = scoped.group(:month).sum(:value)

    @monthly_data = (1..12).map do |month|
      {
        month: month,
        label: I18n.t("date.month_names")[month],
        value: monthly_hash[month].to_f
      }
    end
  end

  def presentation
    @dashboards = [
      { category: "Passagens Aéreas", metric_type: "Quantidade" },
      { category: "Hospedagem", metric_type: "Quantidade" },
      { category: "Translado", metric_type: "Quantidade" }
    ]

    @year = params[:year].presence&.to_i || Date.current.year
  end

  private

  def travel_metric_params
    params.require(:travel_metric).permit(
      :category,
      :metric_type,
      :state,
      :month,
      :year,
      :value,
      :notes
    )
  end
end