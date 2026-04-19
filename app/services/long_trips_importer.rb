require "roo"

class LongTripsImporter
  SHEET_NAME = "TRECHOS_LONGOS".freeze

  def initialize(file_path)
    @file_path = file_path
    @errors = []
    @imported_count = 0
  end

  attr_reader :errors, :imported_count

  def call
    spreadsheet = Roo::Spreadsheet.open(@file_path)
    sheet = spreadsheet.sheet(SHEET_NAME)

    (2..sheet.last_row).each do |row_number|
      row = sheet.row(row_number)

      next if row.compact.empty?

      attributes = build_attributes(row)

      long_trip = LongTrip.new(attributes)

      if long_trip.save
        @imported_count += 1
      else
        @errors << {
          row: row_number,
          traveler_name: attributes[:traveler_name],
          messages: long_trip.errors.full_messages
        }
      end
    end

    self
  end

  private

  def build_attributes(row)
    {
      travel_request_id: integer_value(row[0]),
      traveler_name: string_value(row[1]),
      traveler_sector: string_value(row[2]),
      travel_reason: string_value(row[3]),
      purchase_date: date_value(row[4]),
      travel_date: date_value(row[5]),
      transport_mode: normalized_transport_mode(row[7]),
      origin_city: string_value(row[8]),
      origin_state: string_value(row[9]),
      origin_terminal: string_value(row[10]),
      destination_city: string_value(row[11]),
      destination_state: string_value(row[12]),
      destination_terminal: string_value(row[13]),
      transport_company: string_value(row[14]),
      mileage: decimal_value(row[15]),
      policy_compliant: boolean_value(row[16]),
      non_compliance_reason: string_value(row[17]),
      canceled: boolean_value(row[18]),
      purchase_value_brl: decimal_value(row[19]),
      purchase_value_points: decimal_value(row[20]),
      extra_fees_brl: decimal_value(row[21]),
      refund_value_brl: decimal_value(row[22]),
      refund_value_points: decimal_value(row[23])
    }
  end

  def string_value(value)
    return nil if value.nil?

    text = value.to_s.strip
    text.present? ? text : nil
  end

  def integer_value(value)
    return nil if value.nil? || value.to_s.strip.empty?

    value.to_i
  end

  def decimal_value(value)
    return nil if value.nil? || value.to_s.strip.empty?

    if value.is_a?(Numeric)
      value.to_d
    else
      cleaned = value.to_s.strip
        .gsub(".", "")
        .gsub(",", ".")

      cleaned.to_d
    end
  end

  def date_value(value)
    return nil if value.nil? || value.to_s.strip.empty?

    return value.to_date if value.respond_to?(:to_date)

    Date.strptime(value.to_s.strip, "%d/%m/%Y")
  rescue ArgumentError
    nil
  end

  def boolean_value(value)
    return nil if value.nil?

    normalized = value.to_s.strip.upcase

    return true if ["SIM", "TRUE", "1"].include?(normalized)
    return false if ["NÃO", "NAO", "FALSE", "0"].include?(normalized)

    nil
  end

  def normalized_transport_mode(value)
    normalized = string_value(value)&.upcase
    return nil if normalized.blank?

    case normalized
    when "AÉREO", "AEREO"
      "Aéreo"
    when "RODOVIÁRIO", "RODOVIARIO", "TERRESTRE"
      "Rodoviário"
    when "CARRO"
      "Carro"
    else
      normalized.capitalize
    end
  end
end