module LongTrips
  class DashboardData
    attr_reader :scope, :start_date, :end_date, :sector, :transport_mode, :policy_compliant, :canceled

    def initialize(scope: LongTrip.all, start_date: nil, end_date: nil, sector: nil,
                   transport_mode: nil, policy_compliant: nil, canceled: nil)
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
        lead_time: lead_time_data,
        cancellations: cancellation_data,
        accommodations: accommodation_data,
        transfers: transfer_data,
        journeys: journey_data,
        details: detail_data
      }
      data[:financial] = financial_data if include_financial
      data
    end

    private

    # ---------- base / filtros ----------
    def filtered_scope
      @filtered_scope ||= begin
        result = scope
        result = result.where("travel_date >= ?", start_date) if start_date.present?
        result = result.where("travel_date <= ?", end_date) if end_date.present?
        result = result.where(traveler_sector: sector) if sector.present?
        result = result.where(transport_mode: transport_mode) if transport_mode.present?
        result = result.where(policy_compliant: policy_compliant) unless policy_compliant.nil?
        result = result.where(canceled: canceled) unless canceled.nil?
        result
      end
    end

    def trips
      @trips ||= filtered_scope.to_a
    end

    def selected_travel_ids
      @selected_travel_ids ||= trips.map(&:travel_request_id).compact.uniq
    end

    def supplemental_available?
      defined?(TravelSummary) && TravelSummary.table_exists? &&
        defined?(TravelAccommodation) && TravelAccommodation.table_exists? &&
        defined?(TravelTransfer) && TravelTransfer.table_exists?
    rescue ActiveRecord::StatementInvalid
      false
    end

    def summaries
      return [] unless supplemental_available?
      @summaries ||= begin
        rel = TravelSummary.where(travel_request_id: selected_travel_ids)
        rel = rel.where("outbound_date >= ?", start_date) if start_date.present?
        rel = rel.where("outbound_date <= ?", end_date) if end_date.present?
        rel.to_a
      end
    end

    def accommodations
      return [] unless supplemental_available?
      @accommodations ||= begin
        rel = TravelAccommodation.where(travel_request_id: selected_travel_ids)
        rel = rel.where("check_in_date >= ?", start_date) if start_date.present?
        rel = rel.where("check_in_date <= ?", end_date) if end_date.present?
        rel.to_a
      end
    end

    def transfers
      return [] unless supplemental_available?
      @transfers ||= begin
        rel = TravelTransfer.where(travel_request_id: selected_travel_ids)
        rel = rel.where("travel_date >= ?", start_date) if start_date.present?
        rel = rel.where("travel_date <= ?", end_date) if end_date.present?
        rel = rel.where(traveler_sector: sector) if sector.present?
        rel.to_a
      end
    end

    # ---------- período ----------
    def period_data
      { start_date: effective_start_date, end_date: effective_end_date }
    end

    def effective_start_date
      @effective_start_date ||= start_date || filtered_scope.minimum(:travel_date)
    end

    def effective_end_date
      @effective_end_date ||= end_date || filtered_scope.maximum(:travel_date)
    end

    # ---------- overview ----------
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
        most_frequent_destination: destination_counts.first&.first
      }
    end

    def total_trips = selected_travel_ids.count
    def total_mileage = trips.sum { |t| t.mileage.to_f }.round(1)
    def total_air_mileage = air_trips.sum { |t| t.mileage.to_f }.round(1)
    def total_land_mileage = land_trips.sum { |t| t.mileage.to_f }.round(1)

    def average_lead_time_days
      values = trips.map(&:days_between_purchase_and_trip).compact
      values.empty? ? 0 : (values.sum.to_f / values.size).round(2)
    end

    def canceled_segments = trips.count { |t| t.canceled == true }
    def cancellation_rate = percentage(canceled_segments, trips.count)
    def compliant_segments = trips.count { |t| t.policy_compliant == true }
    def non_compliant_segments = trips.count { |t| t.policy_compliant == false }
    def compliance_rate
      evaluated = trips.count { |t| !t.policy_compliant.nil? }
      percentage(compliant_segments, evaluated)
    end

    # ---------- transporte ----------
    def air_trips
      @air_trips ||= trips.select { |t| %w[aéreo aereo].include?(normalized_transport_mode(t)) }
    end

    def land_trips
      @land_trips ||= trips.select { |t| %w[rodoviário rodoviario terrestre carro].include?(normalized_transport_mode(t)) }
    end

    def normalized_transport_mode(trip) = trip.transport_mode.to_s.strip.downcase

    # ---------- séries mensais ----------
    def monthly_data
      {
        total_segments: monthly_count(trips, :travel_date),
        air_segments: monthly_count(air_trips, :travel_date),
        land_segments: monthly_count(land_trips, :travel_date),
        total_mileage: monthly_sum(trips, :travel_date, :mileage),
        air_mileage: monthly_sum(air_trips, :travel_date, :mileage),
        land_mileage: monthly_sum(land_trips, :travel_date, :mileage),
        average_lead_time_days: monthly_average_lead_time
      }
    end

    def month_range
      first_date, last_date = effective_start_date, effective_end_date
      return [] if first_date.blank? || last_date.blank?
      current = Date.new(first_date.year, first_date.month, 1)
      ending = Date.new(last_date.year, last_date.month, 1)
      result = []
      while current <= ending
        result << current
        current = current.next_month
      end
      result
    end

    def monthly_count(items, date_field)
      grouped = items.select { |x| x.public_send(date_field).present? }
                     .group_by { |x| d=x.public_send(date_field); [d.year,d.month] }
      month_range.map do |date|
        { year: date.year, month: date.month, label: month_label(date), value: grouped.fetch([date.year,date.month],[]).count }
      end
    end

    def monthly_sum(items, date_field, value_field)
      grouped = items.select { |x| x.public_send(date_field).present? }
                     .group_by { |x| d=x.public_send(date_field); [d.year,d.month] }
      month_range.map do |date|
        value = grouped.fetch([date.year,date.month],[]).sum { |x| x.public_send(value_field).to_f }
        { year: date.year, month: date.month, label: month_label(date), value: value.round(2) }
      end
    end

    def monthly_average_lead_time
      grouped = trips.select { |t| t.travel_date.present? }.group_by { |t| [t.travel_date.year,t.travel_date.month] }
      month_range.map do |date|
        values = grouped.fetch([date.year,date.month],[]).map(&:days_between_purchase_and_trip).compact
        avg = values.empty? ? 0 : (values.sum.to_f / values.size).round(2)
        { year: date.year, month: date.month, label: month_label(date), value: avg }
      end
    end

    # ---------- distribuições ----------
    def distribution_data
      {
        sectors: grouped_count(:traveler_sector),
        destinations: destination_counts.to_h,
        transport_companies: grouped_count(:transport_company),
        transport_modes: grouped_count(:transport_mode)
      }
    end

    def grouped_count(field)
      trips.select { |t| t.public_send(field).present? }.group_by { |t| t.public_send(field) }
           .transform_values(&:count).sort_by { |_k,v| -v }.to_h
    end

    def destination_counts
      trips.select { |t| t.destination_city.present? }
           .reject { |t| t.destination_city.to_s.strip.casecmp("João Pessoa").zero? }
           .group_by(&:destination_city).transform_values(&:count).sort_by { |_k,v| -v }
    end

    # ---------- antecedência ----------
    def lead_time_data
      values = trips.map(&:days_between_purchase_and_trip).compact
      buckets = {
        "0 a 3 dias" => values.count { |v| v.between?(0,3) },
        "4 a 7 dias" => values.count { |v| v.between?(4,7) },
        "8 a 14 dias" => values.count { |v| v.between?(8,14) },
        "15 a 30 dias" => values.count { |v| v.between?(15,30) },
        "31 dias ou mais" => values.count { |v| v >= 31 }
      }
      { average_days: average_lead_time_days, distribution: buckets, monthly_average: monthly_average_lead_time }
    end

    # ---------- cancelamentos ----------
    def cancellation_data
      monthly = month_range.map do |date|
        month_items = trips.select { |t| t.travel_date.present? && t.travel_date.year == date.year && t.travel_date.month == date.month }
        canceled_count = month_items.count { |t| t.canceled == true }
        { year: date.year, month: date.month, label: month_label(date), total: month_items.count,
          canceled: canceled_count, value: percentage(canceled_count, month_items.count) }
      end
      { total: canceled_segments, rate: cancellation_rate, monthly_rate: monthly }
    end

    # ---------- hospedagem ----------
    def accommodation_data
      nights = accommodations.sum { |a| a.stay_duration_days.to_i }
      total_value = accommodations.sum { |a| a.total_stay_value_brl.to_f }
      hotel_counts = accommodations.select { |a| a.hotel.present? }.group_by(&:hotel).transform_values(&:count)
      {
        total_records: accommodations.count,
        total_trips: accommodations.map(&:travel_request_id).uniq.count,
        total_nights: nights,
        average_stay_days: accommodations.empty? ? 0 : (nights.to_f / accommodations.count).round(2),
        average_daily_rate_brl: nights.zero? ? 0 : (total_value / nights).round(2),
        unique_hotels: hotel_counts.keys.count,
        top_hotels: hotel_counts.sort_by { |_k,v| -v }.to_h,
        monthly_stays: monthly_count(accommodations, :check_in_date),
        monthly_nights: monthly_sum(accommodations, :check_in_date, :stay_duration_days)
      }
    end

    # ---------- translados ----------
    def transfer_data
      mileage = transfers.sum { |t| t.estimated_mileage.to_f }
      companies = transfers.select { |t| t.company.present? }.group_by(&:company).transform_values(&:count)
      routes = transfers.group_by { |t| [t.origin,t.destination].compact.join(" → ") }.transform_values(&:count)
      {
        total_transfers: transfers.count,
        total_trips: transfers.map(&:travel_request_id).uniq.count,
        total_mileage: mileage.round(1),
        average_mileage: transfers.empty? ? 0 : (mileage / transfers.count).round(1),
        top_companies: companies.sort_by { |_k,v| -v }.to_h,
        top_routes: routes.reject { |k,_| k.blank? }.sort_by { |_k,v| -v }.to_h,
        monthly_transfers: monthly_count(transfers, :travel_date),
        monthly_mileage: monthly_sum(transfers, :travel_date, :estimated_mileage)
      }
    end

    # ---------- viagem consolidada ----------
    def journey_data
      durations = summaries.map(&:duration_days).compact
      {
        total: summaries.count,
        average_duration_days: durations.empty? ? 0 : (durations.sum.to_f / durations.count).round(2),
        monthly: monthly_count(summaries, :outbound_date)
      }
    end

    # ---------- financeiro ----------
    def financial_data
      long_final = trips.sum(&:final_value_brl).round(2)
      summary_total = summaries.sum { |s| s.total_value_brl.to_f }.round(2)
      short_total = summaries.sum { |s| s.short_segments_value_brl.to_f }.round(2)
      hotel_total = summaries.sum { |s| s.accommodation_value_brl.to_f }.round(2)
      long_summary = summaries.sum { |s| s.long_segments_value_brl.to_f }.round(2)
      points_total = summaries.sum { |s| s.total_value_points.to_f }.round(2)

      {
        purchase_value_brl: sum_field(:purchase_value_brl),
        purchase_value_points: sum_field(:purchase_value_points),
        extra_fees_brl: sum_field(:extra_fees_brl),
        refund_value_brl: sum_field(:refund_value_brl),
        refund_value_points: sum_field(:refund_value_points),
        final_value_brl: long_final,
        final_value_points: trips.sum(&:final_value_points).round(2),
        average_final_value_brl_per_segment: trips.empty? ? 0 : (long_final / trips.size.to_f).round(2),
        average_final_value_brl_per_trip: total_trips.zero? ? 0 : (long_final / total_trips.to_f).round(2),
        monthly_final_value_brl: monthly_final_value_brl,
        by_sector: financial_by_field(:traveler_sector),
        by_destination: financial_by_destination,

        journey_total_value_brl: summary_total,
        journey_total_value_points: points_total,
        journey_average_value_brl: summaries.empty? ? 0 : (summary_total / summaries.count).round(2),
        long_segments_total_brl: long_summary,
        short_segments_total_brl: short_total,
        accommodation_total_brl: hotel_total,
        composition: {
          "Trechos longos" => long_summary,
          "Trechos curtos" => short_total,
          "Hospedagem" => hotel_total
        },
        monthly_journey_total_brl: monthly_sum(summaries, :outbound_date, :total_value_brl),
        monthly_long_segments_brl: monthly_sum(summaries, :outbound_date, :long_segments_value_brl),
        monthly_short_segments_brl: monthly_sum(summaries, :outbound_date, :short_segments_value_brl),
        monthly_accommodation_brl: monthly_sum(summaries, :outbound_date, :accommodation_value_brl),
        compliant_cost_per_km: segment_cost_per_km(true),
        non_compliant_cost_per_km: segment_cost_per_km(false)
      }
    end

    def sum_field(field) = trips.sum { |t| t.public_send(field).to_f }.round(2)

    def monthly_final_value_brl
      month_range.map do |date|
        items = trips.select { |t| t.travel_date.present? && t.travel_date.year == date.year && t.travel_date.month == date.month }
        { year: date.year, month: date.month, label: month_label(date), value: items.sum(&:final_value_brl).round(2) }
      end
    end

    def financial_by_field(field)
      trips.select { |t| t.public_send(field).present? }.group_by { |t| t.public_send(field) }
           .transform_values { |items| items.sum(&:final_value_brl).round(2) }.sort_by { |_k,v| -v }.to_h
    end

    def financial_by_destination
      trips.select { |t| t.destination_city.present? }
           .reject { |t| t.destination_city.to_s.strip.casecmp("João Pessoa").zero? }
           .group_by(&:destination_city).transform_values { |items| items.sum(&:final_value_brl).round(2) }
           .sort_by { |_k,v| -v }.to_h
    end

    def segment_cost_per_km(compliance)
      items = trips.select { |t| t.policy_compliant == compliance && t.mileage.to_f.positive? }
      km = items.sum { |t| t.mileage.to_f }
      return 0 if km.zero?
      (items.sum(&:final_value_brl) / km).round(2)
    end

    # ---------- detalhe ----------
    def detail_data
      trips.map do |trip|
        {
          id: trip.id, travel_request_id: trip.travel_request_id,
          traveler_name: trip.traveler_name, traveler_sector: trip.traveler_sector, travel_reason: trip.travel_reason,
          purchase_date: trip.purchase_date, travel_date: trip.travel_date, lead_time_days: trip.days_between_purchase_and_trip,
          transport_mode: trip.transport_mode, origin_city: trip.origin_city, origin_state: trip.origin_state,
          origin_terminal: trip.origin_terminal, destination_city: trip.destination_city, destination_state: trip.destination_state,
          destination_terminal: trip.destination_terminal, transport_company: trip.transport_company, mileage: trip.mileage,
          policy_compliant: trip.policy_compliant, non_compliance_reason: trip.non_compliance_reason, canceled: trip.canceled,
          purchase_value_brl: trip.purchase_value_brl, purchase_value_points: trip.purchase_value_points,
          extra_fees_brl: trip.extra_fees_brl, refund_value_brl: trip.refund_value_brl,
          refund_value_points: trip.refund_value_points, final_value_brl: trip.final_value_brl, final_value_points: trip.final_value_points
        }
      end
    end

    # ---------- utils ----------
    def month_label(date)
      months = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
      "#{months[date.month - 1]} #{date.year}"
    end

    def percentage(numerator, denominator)
      return 0 if denominator.to_i.zero?
      (numerator.to_f / denominator.to_f * 100).round(2)
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
