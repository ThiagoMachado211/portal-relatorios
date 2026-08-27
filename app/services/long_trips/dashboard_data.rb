module LongTrips
  class DashboardData
    FINANCIAL_FIELDS = %i[
      purchase_value_brl
      purchase_value_points
      extra_fees_brl
      refund_value_brl
      refund_value_points
    ].freeze

    attr_reader :scope,
                :start_date,
                :end_date,
                :sector,
                :transport_mode,
                :policy_compliant,
                :canceled

    def initialize(
      scope: LongTrip.all,
      start_date: nil,
      end_date: nil,
      sector: nil,
      transport_mode: nil,
      policy_compliant: nil,
      canceled: nil
    )
      @scope = scope
      @start_date = normalize_date(start_date)
      @end_date = normalize_date(end_date)
      @sector = sector.presence
      @transport_mode = transport_mode.presence
      @policy_compliant = normalize_boolean_filter(policy_compliant)
      @canceled = normalize_boolean_filter(canceled)
    end

    def call(include_financial: true)
      data = {
        period: period_data,
        overview: overview_data,
        monthly: monthly_data,
        distributions: distribution_data,
        details: detail_data
      }

      data[:financial] = financial_data if include_financial

      data
    end

    private

    # =========================================================
    # BASE
    # =========================================================

    def filtered_scope
      @filtered_scope ||= begin
        result = scope

        if start_date.present?
          result = result.where("travel_date >= ?", start_date)
        end

        if end_date.present?
          result = result.where("travel_date <= ?", end_date)
        end

        if sector.present?
          result = result.where(traveler_sector: sector)
        end

        if transport_mode.present?
          result = result.where(transport_mode: transport_mode)
        end

        unless policy_compliant.nil?
          result = result.where(policy_compliant: policy_compliant)
        end

        unless canceled.nil?
          result = result.where(canceled: canceled)
        end

        result
      end
    end

    def trips
      @trips ||= filtered_scope.to_a
    end

    # =========================================================
    # PERÍODO
    # =========================================================

    def period_data
      {
        start_date: effective_start_date,
        end_date: effective_end_date
      }
    end

    
    def effective_start_date
      @effective_start_date ||= (
        start_date || filtered_scope.minimum(:travel_date)
      )
    end

    def effective_end_date
      @effective_end_date ||= (
        end_date || filtered_scope.maximum(:travel_date)
      )
    end


    # =========================================================
    # VISÃO GERAL
    # =========================================================

    def overview_data
      {
        total_trips: total_trips,
        total_segments: trips.count,

        total_air_segments: air_trips.count,
        total_land_segments: land_trips.count,

        total_mileage: total_mileage,
        total_air_mileage: total_air_mileage,
        total_land_mileage: total_land_mileage,

        average_lead_time_days: average_lead_time_days,

        canceled_segments: canceled_segments,
        cancellation_rate: cancellation_rate,

        compliant_segments: compliant_segments,
        non_compliant_segments: non_compliant_segments,
        compliance_rate: compliance_rate,

        most_frequent_destination: most_frequent_destination
      }
    end

    def total_trips
      trips
        .map(&:travel_request_id)
        .reject(&:blank?)
        .uniq
        .count
    end

    def total_mileage
      trips.sum { |trip| trip.mileage.to_f }.round(1)
    end

    def total_air_mileage
      air_trips.sum { |trip| trip.mileage.to_f }.round(1)
    end

    def total_land_mileage
      land_trips.sum { |trip| trip.mileage.to_f }.round(1)
    end

    def average_lead_time_days
      values = trips
        .map(&:days_between_purchase_and_trip)
        .compact

      return 0 if values.empty?

      (values.sum.to_f / values.size).round(2)
    end

    def canceled_segments
      trips.count { |trip| trip.canceled == true }
    end

    def cancellation_rate
      percentage(canceled_segments, trips.count)
    end

    def compliant_segments
      trips.count { |trip| trip.policy_compliant == true }
    end

    def non_compliant_segments
      trips.count { |trip| trip.policy_compliant == false }
    end

    def compliance_rate
      evaluated =
        trips.count do |trip|
          !trip.policy_compliant.nil?
        end

      percentage(compliant_segments, evaluated)
    end

    def most_frequent_destination
      destination_counts.first&.first
    end

    # =========================================================
    # CLASSIFICAÇÃO DE TRANSPORTE
    # =========================================================

    def air_trips
      @air_trips ||= trips.select do |trip|
        %w[aéreo aereo].include?(
          normalized_transport_mode(trip)
        )
      end
    end

    def land_trips
      @land_trips ||= trips.select do |trip|
        [
          "rodoviário",
          "rodoviario",
          "terrestre",
          "carro"
        ].include?(
          normalized_transport_mode(trip)
        )
      end
    end

    def normalized_transport_mode(trip)
      trip.transport_mode
        .to_s
        .strip
        .downcase
    end

    # =========================================================
    # SÉRIES MENSAIS
    # =========================================================

    def monthly_data
      {
        total_segments: monthly_count(trips),
        air_segments: monthly_count(air_trips),
        land_segments: monthly_count(land_trips),

        total_mileage: monthly_sum(trips, :mileage),
        air_mileage: monthly_sum(air_trips, :mileage),
        land_mileage: monthly_sum(land_trips, :mileage),

        average_lead_time_days: monthly_average_lead_time
      }
    end

    def month_range
      first_date = effective_start_date
      last_date = effective_end_date

      return [] if first_date.blank? || last_date.blank?

      current =
        Date.new(
          first_date.year,
          first_date.month,
          1
        )

      ending =
        Date.new(
          last_date.year,
          last_date.month,
          1
        )

      months = []

      while current <= ending
        months << current
        current = current.next_month
      end

      months
    end

    def monthly_count(items)
      grouped =
        items
          .select { |trip| trip.travel_date.present? }
          .group_by do |trip|
            [
              trip.travel_date.year,
              trip.travel_date.month
            ]
          end

      month_range.map do |date|
        key = [date.year, date.month]

        {
          year: date.year,
          month: date.month,
          label: month_label(date),
          value: grouped.fetch(key, []).count
        }
      end
    end

    def monthly_sum(items, field)
      grouped =
        items
          .select { |trip| trip.travel_date.present? }
          .group_by do |trip|
            [
              trip.travel_date.year,
              trip.travel_date.month
            ]
          end

      month_range.map do |date|
        key = [date.year, date.month]

        value =
          grouped
            .fetch(key, [])
            .sum do |trip|
              trip.public_send(field).to_f
            end

        {
          year: date.year,
          month: date.month,
          label: month_label(date),
          value: value.round(2)
        }
      end
    end

    def monthly_average_lead_time
      grouped =
        trips
          .select do |trip|
            trip.travel_date.present? &&
              trip.purchase_date.present?
          end
          .group_by do |trip|
            [
              trip.travel_date.year,
              trip.travel_date.month
            ]
          end

      month_range.map do |date|
        key = [date.year, date.month]

        values =
          grouped
            .fetch(key, [])
            .map(&:days_between_purchase_and_trip)
            .compact

        average =
          if values.empty?
            0
          else
            (values.sum.to_f / values.size).round(2)
          end

        {
          year: date.year,
          month: date.month,
          label: month_label(date),
          value: average
        }
      end
    end

    # =========================================================
    # DISTRIBUIÇÕES
    # =========================================================

    def distribution_data
      {
        sectors: sector_counts,
        destinations: destination_counts.to_h,
        transport_companies: transport_company_counts,
        transport_modes: transport_mode_counts
      }
    end

    def sector_counts
      grouped_count(:traveler_sector)
    end

    def transport_company_counts
      grouped_count(:transport_company)
    end

    def transport_mode_counts
      grouped_count(:transport_mode)
    end

    def destination_counts
      trips
        .select { |trip| trip.destination_city.present? }
        .reject do |trip|
          trip.destination_city
            .to_s
            .strip
            .casecmp("João Pessoa")
            .zero?
        end
        .group_by(&:destination_city)
        .transform_values(&:count)
        .sort_by { |_label, count| -count }
    end

    def grouped_count(field)
      trips
        .select do |trip|
          trip.public_send(field).present?
        end
        .group_by do |trip|
          trip.public_send(field)
        end
        .transform_values(&:count)
        .sort_by { |_label, count| -count }
        .to_h
    end

    # =========================================================
    # FINANCEIRO
    # =========================================================

    def financial_data
      {
        purchase_value_brl:
          sum_field(:purchase_value_brl),

        purchase_value_points:
          sum_field(:purchase_value_points),

        extra_fees_brl:
          sum_field(:extra_fees_brl),

        refund_value_brl:
          sum_field(:refund_value_brl),

        refund_value_points:
          sum_field(:refund_value_points),

        final_value_brl:
          trips.sum(&:final_value_brl).round(2),

        final_value_points:
          trips.sum(&:final_value_points).round(2),

        average_final_value_brl_per_segment:
          average_final_value_brl_per_segment,

        average_final_value_brl_per_trip:
          average_final_value_brl_per_trip,

        monthly_final_value_brl:
          monthly_final_value_brl,

        by_sector:
          financial_by_field(:traveler_sector),

        by_destination:
          financial_by_destination
      }
    end

    def sum_field(field)
      trips
        .sum { |trip| trip.public_send(field).to_f }
        .round(2)
    end

    def average_final_value_brl_per_segment
      return 0 if trips.empty?

      (
        trips.sum(&:final_value_brl) /
        trips.size.to_f
      ).round(2)
    end

    def average_final_value_brl_per_trip
      return 0 if total_trips.zero?

      (
        trips.sum(&:final_value_brl) /
        total_trips.to_f
      ).round(2)
    end

    def monthly_final_value_brl
      grouped =
        trips
          .select { |trip| trip.travel_date.present? }
          .group_by do |trip|
            [
              trip.travel_date.year,
              trip.travel_date.month
            ]
          end

      month_range.map do |date|
        key = [date.year, date.month]

        value =
          grouped
            .fetch(key, [])
            .sum(&:final_value_brl)

        {
          year: date.year,
          month: date.month,
          label: month_label(date),
          value: value.round(2)
        }
      end
    end

    def financial_by_field(field)
      trips
        .select do |trip|
          trip.public_send(field).present?
        end
        .group_by do |trip|
          trip.public_send(field)
        end
        .transform_values do |items|
          items
            .sum(&:final_value_brl)
            .round(2)
        end
        .sort_by { |_label, value| -value }
        .to_h
    end

    def financial_by_destination
      trips
        .select { |trip| trip.destination_city.present? }
        .reject do |trip|
          trip.destination_city
            .to_s
            .strip
            .casecmp("João Pessoa")
            .zero?
        end
        .group_by(&:destination_city)
        .transform_values do |items|
          items
            .sum(&:final_value_brl)
            .round(2)
        end
        .sort_by { |_label, value| -value }
        .to_h
    end

    # =========================================================
    # DETALHAMENTO
    # =========================================================

    def detail_data
      trips.map do |trip|
        {
          id: trip.id,
          travel_request_id: trip.travel_request_id,

          traveler_name: trip.traveler_name,
          traveler_sector: trip.traveler_sector,
          travel_reason: trip.travel_reason,

          purchase_date: trip.purchase_date,
          travel_date: trip.travel_date,

          lead_time_days:
            trip.days_between_purchase_and_trip,

          transport_mode: trip.transport_mode,

          origin_city: trip.origin_city,
          origin_state: trip.origin_state,
          origin_terminal: trip.origin_terminal,

          destination_city: trip.destination_city,
          destination_state: trip.destination_state,
          destination_terminal: trip.destination_terminal,

          transport_company: trip.transport_company,

          mileage: trip.mileage,

          policy_compliant:
            trip.policy_compliant,

          non_compliance_reason:
            trip.non_compliance_reason,

          canceled:
            trip.canceled,

          purchase_value_brl:
            trip.purchase_value_brl,

          purchase_value_points:
            trip.purchase_value_points,

          extra_fees_brl:
            trip.extra_fees_brl,

          refund_value_brl:
            trip.refund_value_brl,

          refund_value_points:
            trip.refund_value_points,

          final_value_brl:
            trip.final_value_brl,

          final_value_points:
            trip.final_value_points
        }
      end
    end


    # =========================================================
    # UTILITÁRIOS
    # =========================================================

    def month_label(date)
      months = [
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

      "#{months[date.month - 1]} #{date.year}"
    end

    def percentage(numerator, denominator)
      return 0 if denominator.to_i.zero?

      (
        numerator.to_f /
        denominator.to_f *
        100
      ).round(2)
    end

    def normalize_boolean_filter(value)
      return nil if value.blank?
      return true if value.to_s == "true"
      return false if value.to_s == "false"

      nil
    end

    def normalize_date(value)
      return value if value.is_a?(Date)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end