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
    @display_mode = params[:display]
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
    when "sector_distribution_monthly"
      load_sector_distribution_monthly_data
    when "destination_cities"
      load_destination_cities_data
    when "destination_cities_monthly"
      load_destination_cities_monthly_data
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
      "sector_distribution_monthly",
      "destination_cities",
      "destination_cities_monthly"
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

  def quarter_months
    [1, 2, 3]
  end

  def monthly_labels
    {
      1 => "Janeiro",
      2 => "Fevereiro",
      3 => "Março"
    }
  end

  def trips_in_quarter(trips)
    trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }
  end

  def build_monthly_count_data(trips)
    counts = trips_in_quarter(trips)
      .group_by { |trip| trip.travel_date.month }
      .transform_values(&:count)

    quarter_months.map do |month|
      {
        label: monthly_labels[month],
        value: counts[month].to_i
      }
    end
  end

  def build_monthly_mileage_data(trips)
    sums = trips_in_quarter(trips)
      .group_by { |trip| trip.travel_date.month }
      .transform_values { |items| items.sum { |trip| trip.mileage.to_f } }

    quarter_months.map do |month|
      {
        label: monthly_labels[month],
        value: sums[month].to_f.round(1)
      }
    end
  end

  def build_monthly_lead_time_data(trips)
    grouped = trips
      .select { |trip| trip.travel_date.present? && trip.purchase_date.present? && quarter_months.include?(trip.travel_date.month) }
      .group_by { |trip| trip.travel_date.month }

    quarter_months.map do |month|
      values = (grouped[month] || []).map(&:days_between_purchase_and_trip).compact
      avg = values.any? ? (values.sum.to_f / values.size).round(2) : 0

      {
        label: monthly_labels[month],
        value: avg
      }
    end
  end

  def destination_frequency_scope(trips = @long_trips)
    trips
      .select { |trip| trip.destination_city.present? }
      .reject { |trip| trip.destination_city.to_s.strip.casecmp("João Pessoa").zero? }
      .group_by(&:destination_city)
      .transform_values(&:count)
  end

  def load_overview_data
    quarter_long_trips = @long_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }
    quarter_air_trips = air_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }
    quarter_land_trips = land_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }

    destination_frequency = destination_frequency_scope(quarter_long_trips)

    air_days = quarter_air_trips.map(&:days_between_purchase_and_trip).compact

    @overview_cards = [
      { label: "Total de Passagens Aéreas", value: quarter_air_trips.count },
      { label: "Total de Passagens Terrestres", value: quarter_land_trips.count },
      { label: "Quilometragem Total (Aéreas)", value: quarter_air_trips.sum { |trip| trip.mileage.to_f }.round(1) },
      { label: "Quilometragem Total (Terrestres)", value: quarter_land_trips.sum { |trip| trip.mileage.to_f }.round(1) },
      { label: "Média Dias de Antecedência (Aéreas)", value: air_days.any? ? (air_days.sum.to_f / air_days.size).round(2) : 0 },
      { label: "Total de Cancelamentos (Aéreas)", value: quarter_air_trips.count { |trip| trip.canceled == true } },
      { label: "Total de Cancelamentos (Terrestres)", value: quarter_land_trips.count { |trip| trip.canceled == true } },
      {
        label: "Taxa de Cancelamento (Aéreas)",
        value: if quarter_air_trips.any?
                 (((quarter_air_trips.count { |trip| trip.canceled == true }.to_f / quarter_air_trips.count) * 100).round(2)).to_s + "%"
               else
                 "0%"
               end
      },
      { label: "Destino mais frequente", value: destination_frequency.max_by { |_city, count| count }&.first || "-" }
    ]
  end

  def load_air_quantity_data
    @dashboard_title = "Passagens Aéreas: Quantidade"
    @monthly_series = build_monthly_count_data(air_trips)
  end

  def load_land_quantity_data
    @dashboard_title = "Passagens Terrestres: Quantidade"
    @monthly_series = build_monthly_count_data(land_trips)
  end

  def load_air_mileage_data
    @dashboard_title = "Passagens Aéreas: Quilometragem"
    @monthly_series = build_monthly_mileage_data(air_trips)
  end

  def load_land_mileage_data
    @dashboard_title = "Passagens Terrestres: Quilometragem"
    @monthly_series = build_monthly_mileage_data(land_trips)
  end

  def load_lead_time_data
    @dashboard_title = "Passagens Aéreas: Antecedência de Compra"
    @monthly_series = build_monthly_lead_time_data(air_trips)
  end

  def load_sector_distribution_data
    quarter_long_trips = @long_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }

    @dashboard_title = "Distribuição por Setor"
    @bar_title = "Distribuição por Setor das Passagens"
    @sector_data = quarter_long_trips
      .select { |trip| trip.traveler_sector.present? }
      .group_by(&:traveler_sector)
      .transform_values(&:count)
      .sort_by { |_sector, count| -count }
      .to_h
  end

  def load_sector_distribution_monthly_data
    quarter_long_trips = @long_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }

    @dashboard_title = "Distribuição por Setor por Mês"

    @monthly_sector_cards = quarter_months.map do |month|
      trips_in_month = quarter_long_trips.select { |trip| trip.travel_date.month == month }

      data = trips_in_month
        .select { |trip| trip.traveler_sector.present? }
        .group_by(&:traveler_sector)
        .transform_values(&:count)
        .sort_by { |_sector, count| -count }
        .to_h

      { title: monthly_labels[month], data: data }
    end
  end

  def load_destination_cities_data
    quarter_long_trips = @long_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }

    @dashboard_title = "Cidades de Destino"
    @bar_title = "Frequência de Cidades de Destino"
    @city_data = destination_frequency_scope(quarter_long_trips)
      .sort_by { |_city, count| -count }
      .to_h
  end

  def load_destination_cities_monthly_data
    quarter_long_trips = @long_trips.select { |trip| trip.travel_date.present? && quarter_months.include?(trip.travel_date.month) }

    @dashboard_title = "Cidades de Destino por Mês"

    @monthly_city_cards = quarter_months.map do |month|
      trips_in_month = quarter_long_trips.select { |trip| trip.travel_date.month == month }

      data = destination_frequency_scope(trips_in_month)
        .sort_by { |_city, count| -count }
        .to_h

      { title: monthly_labels[month], data: data }
    end
  end
end