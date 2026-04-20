require "csv"

class LongTripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_long_trip, only: []

  def index
    redirect_to dashboard_long_trips_path
  end

  def new
    @long_trip = LongTrip.new
  end

  def create
    @long_trip = LongTrip.new(long_trip_params)

    if @long_trip.save
      redirect_to dashboard_long_trips_path, notice: "Registro de viagem criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    load_dashboard_page
    render :dashboard
  end

  def presentation
    load_dashboard_page
    render :presentation
  end

  def import
  end

  def import_file
    if params[:file].blank?
      redirect_to import_long_trips_path, alert: "Selecione um arquivo CSV para importar."
      return
    end

    imported_count = 0
    errors = []

    begin
      CSV.foreach(params[:file].path, headers: true, col_sep: detect_col_sep(params[:file].path), encoding: "bom|utf-8") do |row|
        long_trip = LongTrip.new(
          travel_request_id: integer_or_nil(row["travel_request_id"]),
          traveler_name: row["traveler_name"],
          traveler_sector: row["traveler_sector"],
          travel_reason: row["travel_reason"],
          purchase_date: date_or_nil(row["purchase_date"]),
          travel_date: date_or_nil(row["travel_date"]),
          transport_mode: row["transport_mode"],
          origin_city: row["origin_city"],
          origin_state: row["origin_state"],
          origin_terminal: row["origin_terminal"],
          destination_city: row["destination_city"],
          destination_state: row["destination_state"],
          destination_terminal: row["destination_terminal"],
          transport_company: row["transport_company"],
          mileage: decimal_or_nil(row["mileage"]),
          policy_compliant: boolean_or_nil(row["policy_compliant"]),
          non_compliance_reason: row["non_compliance_reason"],
          canceled: boolean_or_nil(row["canceled"]),
          purchase_value_brl: decimal_or_nil(row["purchase_value_brl"]),
          purchase_value_points: decimal_or_nil(row["purchase_value_points"]),
          extra_fees_brl: decimal_or_nil(row["extra_fees_brl"]),
          refund_value_brl: decimal_or_nil(row["refund_value_brl"]),
          refund_value_points: decimal_or_nil(row["refund_value_points"])
        )

        if long_trip.save
          imported_count += 1
        else
          errors << "Linha #{row.to_h.inspect}: #{long_trip.errors.full_messages.join(', ')}"
        end
      end
    rescue StandardError => e
      redirect_to import_long_trips_path, alert: "Erro ao importar arquivo: #{e.message}"
      return
    end

    if errors.any?
      redirect_to import_long_trips_path,
                  alert: "Importação concluída com #{imported_count} registros salvos, mas houve erros.",
                  flash: { import_errors: errors.first(10) }
    else
      redirect_to dashboard_long_trips_path, notice: "#{imported_count} registros importados com sucesso."
    end
  end

  private

  def load_dashboard_page
    @page = params[:page].presence || "overview"
    @dashboard_title = "Gestão de Viagens"
    @monthly_series = []
    @summary_cards = build_summary_cards

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
    end
  end

  def build_summary_cards
    [
      {
        title: "Total de viagens",
        value: base_scope.count
      },
      {
        title: "Viagens aéreas",
        value: air_scope.count
      },
      {
        title: "Viagens terrestres",
        value: land_scope.count
      },
      {
        title: "Quilometragem total",
        value: format_number(base_scope.sum(:mileage))
      }
    ]
  end

  def base_scope
    LongTrip.all
  end

  def air_scope
    base_scope.where("LOWER(COALESCE(transport_mode, '')) IN (?)", air_modes)
  end

  def land_scope
    base_scope.where("LOWER(COALESCE(transport_mode, '')) IN (?)", land_modes)
  end

  def air_modes
    ["aéreo", "aereo", "aérea", "aerea", "air", "flight", "avião", "aviao"]
  end

  def land_modes
    ["terrestre", "rodoviário", "rodoviario", "ground", "bus", "ônibus", "onibus", "carro"]
  end

  def monthly_count_series(scope:)
    grouped_by_month(scope).map do |month_name, records|
      { label: month_name, value: records.size }
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
      { label: month_name, value: average }
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
        { label: "#{month_name} - #{top_item[:label]}", value: top_item[:value] }
      else
        { label: month_name, value: 0 }
      end
    end
  end

  def grouped_by_month(scope)
    grouped = Hash.new { |hash, key| hash[key] = [] }

    scope.find_each do |record|
      date = reference_date_for(record)
      next if date.blank?

      grouped[month_name_pt_br(date.month)] << record
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
      "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
      "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ][month_number]
  end

  def format_number(value)
    numeric_value(value).round(2)
  end

  def numeric_value(value)
    return 0 if value.blank?

    value.to_d.to_f
  rescue StandardError
    0
  end

  def integer_or_nil(value)
    return nil if value.blank?

    value.to_i
  end

  def decimal_or_nil(value)
    return nil if value.blank?

    value.to_s.tr(",", ".").to_d
  end

  def date_or_nil(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue StandardError
    nil
  end

  def boolean_or_nil(value)
    return nil if value.blank?

    normalized = value.to_s.strip.downcase
    return true if %w[true t 1 sim yes y].include?(normalized)
    return false if %w[false f 0 nao não no n].include?(normalized)

    nil
  end

  def detect_col_sep(path)
    first_line = File.open(path, &:readline)
    first_line.include?(";") ? ";" : ","
  rescue StandardError
    ","
  end

  def set_long_trip
    @long_trip = LongTrip.find(params[:id])
  end

  def long_trip_params
    params.require(:long_trip).permit(
      :travel_request_id,
      :traveler_name,
      :traveler_sector,
      :travel_reason,
      :purchase_date,
      :travel_date,
      :transport_mode,
      :origin_city,
      :origin_state,
      :origin_terminal,
      :destination_city,
      :destination_state,
      :destination_terminal,
      :transport_company,
      :mileage,
      :policy_compliant,
      :non_compliance_reason,
      :canceled,
      :purchase_value_brl,
      :purchase_value_points,
      :extra_fees_brl,
      :refund_value_brl,
      :refund_value_points
    )
  end
end