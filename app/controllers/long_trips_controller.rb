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
    @long_trips = LongTrip.all

    air_trips = @long_trips.select do |trip|
      mode = trip.transport_mode.to_s.downcase
      mode == "aéreo" || mode == "aereo"
    end

    land_trips = @long_trips.select do |trip|
      mode = trip.transport_mode.to_s.downcase
      mode == "rodoviário" || mode == "rodoviario" || mode == "terrestre"
    end

    @total_air_tickets = air_trips.count
    @total_land_tickets = land_trips.count

    air_days = air_trips.map(&:days_between_purchase_and_trip).compact
    @average_air_days_between = air_days.any? ? (air_days.sum.to_f / air_days.size).round(1) : 0

    @total_air_mileage = air_trips.sum { |trip| trip.mileage.to_f }
    @total_land_mileage = land_trips.sum { |trip| trip.mileage.to_f }

    destination_frequency = @long_trips
      .select { |trip| trip.destination_city.present? }
      .group_by(&:destination_city)
      .transform_values(&:count)

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

  def presentation
    dashboard
    render :presentation
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
end