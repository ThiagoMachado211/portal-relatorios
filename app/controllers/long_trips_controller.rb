class LongTripsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to dashboard_long_trips_path
  end

  def dashboard
    load_dashboard_page
    render :dashboard
  end

  def presentation
    load_dashboard_page
    render :presentation
  end

  private

  def load_dashboard_page
    @page = params[:page].presence || "overview"
    @dashboard_title = "Gestão de Viagens"
    @monthly_series = []

    case @page
    when "overview"
      @dashboard_title = "Visão Geral"

    when "air_quantity"
      @dashboard_title = "Passagens Aéreas: Quantidade"
      @monthly_series = monthly_count_series(scope: air_scope)

    when "land_quantity"
      @dashboard_title = "Passagens Terrestres: Quantidade"
      @monthly_series = monthly_count_series(scope: land_scope)

    when "air_mileage"
      @dashboard_title = "Passagens Aéreas: Quilometragem"
      @monthly_series = monthly_sum_series(scope: air_scope, field: :mileage)

    when "land_mileage"
      @dashboard_title = "Passagens Terrestres: Quilometragem"
      @monthly_series = monthly_sum_series(scope: land_scope, field: :mileage)

    when "lead_time"
      @dashboard_title = "Passagens Aéreas: Antecedência de Compra"
      @monthly_series = monthly_lead_time_series(scope: air_scope)

    when "sector_distribution"
      @dashboard_title = "Distribuição por Setor"
      @monthly_series = grouped_count_series(scope: base_scope, field: :traveler_sector)

    when "sector_distribution_monthly"
      @dashboard_title = "Distribuição por Setor: Evolução Mensal"
      @monthly_series = monthly_top_group_series(scope: base_scope, field: :traveler_sector)

    when "destination_cities"
      @dashboard_title = "Cidades de Destino"
      @monthly_series = grouped_count_series(scope: base_scope, field: :destination_city)

    when "destination_cities_monthly"
      @dashboard_title = "Cidades de Destino: Evolução Mensal"
      @monthly_series = monthly_top_group_series(scope: base_scope, field: :destination_city)

    else
      @page = "overview"
      @dashboard_title = "Visão Geral"
      @monthly_series = []
    end
  end

  def base_scope
    LongTrip.all
  end

  def air_scope
    base_scope.where("LOWER(transport_mode) IN (?)", air_modes)
  end

  def land_scope
    base_scope.where("LOWER(transport_mode) IN (?)", land_modes)
  end

  def air_modes
    [
      "aéreo",
      "aereo",
      "aérea",
      "aerea",
      "air",
      "flight",
      "avião",
      "aviao"
    ]
  end

  def land_modes
    [
      "terrestre",
      "rodoviário",
      "rodoviario",
      "ground",
      "bus",
      "ônibus",
      "onibus",
      "carro"
    ]
  end

  def monthly_count_series(scope:)
    grouped_by_month(scope).map do |month_name, records|
      {
        label: month_name,
        value: records.size
      }
    end
  end

  def monthly_sum_series(scope:, field:)
    grouped_by_month(scope).map do |month_name, records|
      {
        label: month_name,
        value: records.sum { |record| numeric_value(record.public_send(field)) }.round(2)
      }
    end
  end

  def monthly_lead_time_series(scope:)
    grouped_by_month(scope).map do |month_name, records|
      lead_times = records.filter_map do |record|
        next if record.purchase_date.blank? || record.travel_date.blank?

        (record.travel_date - record.purchase_date).to_i
      end

      average = lead_times.any? ? (lead_times.sum.to_f / lead_times.size).round(2) : 0

      {
        label: month_name,
        value: average
      }
    end
  end

  def grouped_count_series(scope:, field:, limit: 10)
    grouped = scope.to_a.group_by do |record|
      value = record.public_send(field)
      value.present? ? value.to_s.strip : "Não informado"
    end

    grouped
      .map { |label, records| { label: label, value: records.size } }
      .sort_by { |item| -item[:value] }
      .first(limit)
  end

  def monthly_top_group_series(scope:, field:)
    grouped_by_month(scope).map do |month_name, records|
      monthly_group = records.group_by do |record|
        value = record.public_send(field)
        value.present? ? value.to_s.strip : "Não informado"
      end

      top_item = monthly_group
        .map { |label, grouped_records| { label: label, value: grouped_records.size } }
        .max_by { |item| item[:value] }

      if top_item.present?
        {
          label: "#{month_name} - #{top_item[:label]}",
          value: top_item[:value]
        }
      else
        {
          label: month_name,
          value: 0
        }
      end
    end
  end

  def grouped_by_month(scope)
    grouped = Hash.new { |hash, key| hash[key] = [] }

    scope.find_each do |record|
      date = reference_date_for(record)
      next if date.blank?

      month_name = month_name_pt_br(date.month)
      grouped[month_name] << record
    end

    ordered_months = [
      "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
      "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    ordered_months.each_with_object({}) do |month_name, result|
      result[month_name] = grouped[month_name] if grouped.key?(month_name)
    end
  end

  def reference_date_for(record)
    record.travel_date || record.purchase_date || record.created_at&.to_date
  end

  def month_name_pt_br(month_number)
    [
      nil,
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ][month_number]
  end

  def numeric_value(value)
    return 0 if value.blank?

    value.to_d.to_f
  rescue StandardError
    0
  end
end