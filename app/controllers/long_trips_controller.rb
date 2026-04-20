class LongTripsController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @page = params[:page].presence || "overview"
    @dashboard_title = "Gestão de Viagens"
    @monthly_series = []
    @summary_cards = []
    @overview_groups = []

    case @page
    when "overview"
      build_overview_page

    when "air_quantity"
      @dashboard_title = "Passagens Aéreas: Quantidade"
      @monthly_series = monthly_count_series(modal: "Aéreo")

    when "land_quantity"
      @dashboard_title = "Passagens Terrestres: Quantidade"
      @monthly_series = monthly_count_series(modal: "Terrestre")

    when "air_mileage"
      @dashboard_title = "Passagens Aéreas: Quilometragem"
      @monthly_series = monthly_sum_series(field: :mileage, modal: "Aéreo")

    when "land_mileage"
      @dashboard_title = "Passagens Terrestres: Quilometragem"
      @monthly_series = monthly_sum_series(field: :mileage, modal: "Terrestre")

    when "lead_time"
      @dashboard_title = "Passagens Aéreas: Antecedência de Compra"
      @monthly_series = monthly_average_series(field: :lead_time, modal: "Aéreo")

    when "sector_distribution"
      @dashboard_title = "Distribuição por Setor"
      @monthly_series = grouped_count_series(field: :sector)

    when "sector_distribution_monthly"
      @dashboard_title = "Distribuição por Setor: Evolução Mensal"
      @monthly_series = monthly_count_series_grouped_label(field: :sector)

    when "destination_cities"
      @dashboard_title = "Cidades de Destino"
      @monthly_series = grouped_count_series(field: :destination_city)

    when "destination_cities_monthly"
      @dashboard_title = "Cidades de Destino: Evolução Mensal"
      @monthly_series = monthly_count_series_grouped_label(field: :destination_city)

    else
      @page = "overview"
      build_overview_page
    end

    @monthly_series ||= []
  end

  private

  def base_scope
    LongTrip.all
  end

  def build_overview_page
    @dashboard_title = "Visão Geral"

    @summary_cards = [
      {
        title: "Passagens Aéreas",
        value: base_scope.where(modal: "Aéreo").count
      },
      {
        title: "Passagens Terrestres",
        value: base_scope.where(modal: "Terrestre").count
      },
      {
        title: "Quilometragem Aérea",
        value: safe_sum(base_scope.where(modal: "Aéreo"), :mileage)
      },
      {
        title: "Quilometragem Terrestre",
        value: safe_sum(base_scope.where(modal: "Terrestre"), :mileage)
      }
    ]

    @overview_groups = [
      {
        title: "Quantidade de Passagens",
        links: [
          { label: "Aéreas", page: "air_quantity" },
          { label: "Terrestres", page: "land_quantity" }
        ]
      },
      {
        title: "Quilometragem",
        links: [
          { label: "Aéreas", page: "air_mileage" },
          { label: "Terrestres", page: "land_mileage" }
        ]
      },
      {
        title: "Antecedência",
        links: [
          { label: "Lead Time", page: "lead_time" }
        ]
      },
      {
        title: "Distribuições",
        links: [
          { label: "Setor", page: "sector_distribution" },
          { label: "Setor por mês", page: "sector_distribution_monthly" },
          { label: "Cidades de destino", page: "destination_cities" },
          { label: "Cidades por mês", page: "destination_cities_monthly" }
        ]
      }
    ]
  end

  def monthly_count_series(modal: nil)
    scope = base_scope
    scope = scope.where(modal: modal) if modal.present?

    grouped_by_month(scope).map do |month_name, records|
      {
        label: month_name,
        value: records.size
      }
    end
  end

  def monthly_sum_series(field:, modal: nil)
    scope = base_scope
    scope = scope.where(modal: modal) if modal.present?

    grouped_by_month(scope).map do |month_name, records|
      {
        label: month_name,
        value: records.sum { |record| numeric_value(record.public_send(field)) }
      }
    end
  end

  def monthly_average_series(field:, modal: nil)
    scope = base_scope
    scope = scope.where(modal: modal) if modal.present?

    grouped_by_month(scope).map do |month_name, records|
      values = records.map { |record| numeric_value(record.public_send(field)) }.select { |v| v > 0 }
      avg = values.any? ? (values.sum.to_f / values.size) : 0

      {
        label: month_name,
        value: avg.round(2)
      }
    end
  end

  def grouped_count_series(field:)
    grouped = base_scope.group_by do |record|
      value = record.public_send(field)
      value.present? ? value.to_s : "Não informado"
    end

    grouped
      .map { |label, records| { label: label, value: records.size } }
      .sort_by { |item| -item[:value] }
      .first(10)
  end

  def monthly_count_series_grouped_label(field:)
    grouped = grouped_by_month(base_scope)

    grouped.map do |month_name, records|
      month_group = records.group_by do |record|
        value = record.public_send(field)
        value.present? ? value.to_s : "Não informado"
      end

      top_item = month_group
        .map { |label, grouped_records| { label: "#{month_name} - #{label}", value: grouped_records.size } }
        .max_by { |item| item[:value] }

      top_item || { label: month_name, value: 0 }
    end
  end

  def grouped_by_month(scope)
    month_order = [
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
    ]

    grouped = Hash.new { |hash, key| hash[key] = [] }

    scope.find_each do |record|
      date = extract_reference_date(record)
      next unless date

      month_name = I18n.l(date, format: "%B").capitalize
      grouped[month_name] << record
    end

    month_order.each_with_object({}) do |month_name, ordered|
      ordered[month_name] = grouped[month_name] if grouped.key?(month_name)
    end
  end

  def extract_reference_date(record)
    possible_fields = %i[
      trip_date
      departure_date
      date
      travel_date
      created_at
    ]

    possible_fields.each do |field|
      next unless record.respond_to?(field)

      value = record.public_send(field)
      return value.to_date if value.present?
    end

    nil
  end

  def safe_sum(scope, field)
    scope.to_a.sum { |record| numeric_value(record.public_send(field)) }
  end

  def numeric_value(value)
    return 0 if value.blank?

    if value.is_a?(String)
      value.tr(",", ".").to_f
    else
      value.to_f
    end
  rescue StandardError
    0
  end
end