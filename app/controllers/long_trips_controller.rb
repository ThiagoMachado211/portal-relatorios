class LongTripsController < ApplicationController
  before_action :authenticate_user!

  def index
    @long_trips = LongTrip.order(created_at: :desc)
  end

  def new
    @long_trip = LongTrip.new
  end

  def create
    @long_trip = LongTrip.new(long_trip_params)

    if @long_trip.save
      redirect_to long_trips_path, notice: "Trecho longo criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def dashboard
    @page = params[:page].presence || "overview"
    @long_trips = LongTrip.all

    case @page
    when "overview"
      load_overview_data
    when "air_quantity"
      load_air_quantity_data
    when "land_quantity"
      load_land_quantity_data
    when "air_mileage"
      load_air_mileage_data
    when "land_mileage"
      load_land_mileage_data
    when "lead_time"
      load_lead_time_data
    when "sector_distribution"
      load_sector_distribution_data
    when "destination_cities"
      load_destination_cities_data
    else
      @page = "overview"
      load_overview_data
    end
  end

  def presentation
    @pages = presentation_pages
  end

  def import
  end

  def import_file
    if params[:file].blank?
      redirect_to import_long_trips_path, alert: "Selecione um arquivo."
      return
    end

    file = params[:file]

    importer = LongTripsImporter.new(file.path).call

    if importer.errors.any?
      flash[:alert] = "Importação concluída com erros."
    else
      flash[:notice] = "Importação concluída com sucesso."
    end

    redirect_to long_trips_path
  end

  private

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

  def presentation_pages
    [
      "overview",
      "air_quantity",
      "land_quantity",
      "air_mileage",
      "land_mileage",
      "lead_time",
      "sector_distribution",
      "destination_cities"
    ]
  end

  def normalized_transport_mode(trip)
    trip.transport_mode.to_s.strip.downcase
  end

  def air_trips
    @long_trips.select do |trip|
      mode = normalized_transport_mode(trip)
      ["aéreo", "aereo"].include?(mode)
    end
  end

  def land_trips
    @long_trips.select do |trip|
      mode = normalized_transport_mode(trip)
      ["rodoviário", "rodoviario", "terrestre", "carro"].include?(mode)
    end
  end

  def monthly_labels
    {
      1 => "Janeiro",
      2 => "Fevereiro",
      3 => "Março",
      4 => "Abril",
      5 => "Maio",
      6 => "Junho",
      7 => "Julho",
      8 => "Agosto",
      9 => "Setembro",
      10 => "Outubro",
      11 => "Novembro",
      12 => "Dezembro"
    }
  end

  def build_monthly_count_data(trips)
    counts = trips
      .select { |trip| trip.travel_date.present? }
      .group_by { |trip| trip.travel_date.month }
      .transform_values(&:count)

    (1..12).map do |month|
      {
        label: monthly_labels[month],
        value: counts[month].to_i
      }
    end
  end

  def build_monthly_mileage_data(trips)
    sums = trips
      .select { |trip| trip.travel_date.present? }
      .group_by { |trip| trip.travel_date.month }
      .transform_values { |items| items.sum { |trip| trip.mileage.to_f } }

    (1..12).map do |month|
      {
        label: monthly_labels[month],
        value: sums[month].to_f
      }
    end
  end

  def build_monthly_lead_time_data(trips)
    grouped = trips
      .select { |trip| trip.travel_date.present? && trip.purchase_date.present? }
      .group_by { |trip| trip.travel_date.month }

    (1..12).map do |month|
      values = (grouped[month] || []).map(&:days_between_purchase_and_trip).compact
      avg = values.any? ? (values.sum.to_f / values.size).round(1) : 0

      {
        label: monthly_labels[month],
        value: avg
      }
    end
  end

  def load_overview_data
    destination_frequency = @long_trips
      .select { |trip| trip.destination_city.present? }
      .group_by(&:destination_city)
      .transform_values(&:count)

    @total_air_tickets = air_trips.count
    @total_land_tickets = land_trips.count

    air_days = air_trips.map(&:days_between_purchase_and_trip).compact
    @average_air_days_between = air_days.any? ? (air_days.sum.to_f / air_days.size).round(1) : 0

    @total_air_mileage = air_trips.sum { |trip| trip.mileage.to_f }
    @total_land_mileage = land_trips.sum { |trip| trip.mileage.to_f }

    @most_frequent_destination = destination_frequency.max_by { |_city, count| count }

    @total_air_cancellations = air_trips.count { |trip| trip.canceled == true }
    @total_land_cancellations = land_trips.count { |trip| trip.canceled == true }

    @air_cancellation_rate =
      if @total_air_tickets.positive?
        ((@total_air_cancellations.to_f / @total_air_tickets) * 100).round(1)
      else
        0
      end

    @sector_distribution = @long_trips
      .select { |trip| trip.traveler_sector.present? }
      .group_by(&:traveler_sector)
      .transform_values(&:count)

    @destination_distribution = destination_frequency
  end

  def load_air_quantity_data
    @dashboard_title = "Passagens Aéreas: Quantidade"
    @kpi_title = "Quantidade Total de Passagens Aéreas"
    @kpi_value = air_trips.count
    @monthly_series = build_monthly_count_data(air_trips)
  end

  def load_land_quantity_data
    @dashboard_title = "Passagens Terrestres: Quantidade"
    @kpi_title = "Quantidade Total de Passagens Terrestres"
    @kpi_value = land_trips.count
    @monthly_series = build_monthly_count_data(land_trips)
  end

  def load_air_mileage_data
    @dashboard_title = "Passagens Aéreas: Quilometragem"
    @kpi_title = "Quilometragem Total de Passagens Aéreas"
    @kpi_value = air_trips.sum { |trip| trip.mileage.to_f }.round(1)
    @monthly_series = build_monthly_mileage_data(air_trips)
  end

  def load_land_mileage_data
    @dashboard_title = "Passagens Terrestres: Quilometragem"
    @kpi_title = "Quilometragem Total de Passagens Terrestres"
    @kpi_value = land_trips.sum { |trip| trip.mileage.to_f }.round(1)
    @monthly_series = build_monthly_mileage_data(land_trips)
  end

  def load_lead_time_data
    air = air_trips
    values = air.map(&:days_between_purchase_and_trip).compact
    @dashboard_title = "Passagens Aéreas: Antecedência de Compra"
    @kpi_title = "Tempo Médio de Antecedência de Compra (Dias)"
    @kpi_value = values.any? ? (values.sum.to_f / values.size).round(1) : 0
    @monthly_series = build_monthly_lead_time_data(air)
  end

  def load_sector_distribution_data
    @dashboard_title = "Distribuição por Setor"
    @pie_title = "Distribuição por Setor das Passagens"
    @pie_data = @long_trips
      .select { |trip| trip.traveler_sector.present? }
      .group_by(&:traveler_sector)
      .transform_values(&:count)
  end

  def load_destination_cities_data
    @dashboard_title = "Cidades de Destino"
    @bar_title = "Frequência de Cidades de Destino"
    @city_data = @long_trips
      .select { |trip| trip.destination_city.present? }
      .group_by(&:destination_city)
      .transform_values(&:count)
      .sort_by { |_city, count| -count }
      .to_h
  end
end