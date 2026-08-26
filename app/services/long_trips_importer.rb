require "csv"

class LongTripsImporter
  attr_reader :imported_count,
              :updated_count,
              :skipped_count,
              :errors

  HEADER_MAP = {
    "ID da viagem" => :travel_request_id,
    "Nome do viajante" => :traveler_name,
    "Setor do viajante" => :traveler_sector,
    "Motivo da viagem" => :travel_reason,

    "Data da compra" => :purchase_date,
    "Data da viagem" => :travel_date,

    "Meio de transporte" => :transport_mode,

    "Cidade origem" => :origin_city,
    "Estado origem" => :origin_state,
    "Nome do aeroporto ou rodoviária" => :origin_terminal,

    "Cidade destino" => :destination_city,
    "Estado destino" => :destination_state,

    "Nome da empresa de transporte" => :transport_company,

    "Quilometragem" => :mileage,

    "Cumpriu política?" => :policy_compliant,
    "Motivo do não-cumprimento" => :non_compliance_reason,

    "Passagem foi cancelada?" => :canceled,

    "Valor da compra (R$)" => :purchase_value_brl,
    "Valor da compra (Pontos)" => :purchase_value_points,

    "Taxas extras (R$)" => :extra_fees_brl,

    "Valor Reembolso (R$)" => :refund_value_brl,
    "Valor Reembolso (Pontos)" => :refund_value_points
  }.freeze

  def initialize(file_path)
    @file_path = file_path

    @imported_count = 0
    @updated_count = 0
    @skipped_count = 0
    @errors = []
  end

  def call
    rows = read_rows

    return self if errors.any?

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        import_row(row, index + 2)
      end
    end

    self
  rescue StandardError => e
    errors << "Erro geral na importação: #{e.message}"

    self
  end

  private

  # =========================================================
  # LEITURA
  # =========================================================

  def read_rows
    CSV.read(
      @file_path,
      headers: true,
      encoding: "bom|utf-8",
      liberal_parsing: true
    )
  rescue CSV::MalformedCSVError => e
    errors << "CSV inválido: #{e.message}"
    []
  rescue StandardError => e
    errors << "Não foi possível ler o arquivo: #{e.message}"
    []
  end

  # =========================================================
  # IMPORTAÇÃO DE UMA LINHA
  # =========================================================

  def import_row(row, line_number)
    return skip_row if blank_row?(row)

    attributes = build_attributes(row)

    unless valid_minimum_data?(attributes)
      @skipped_count += 1

      errors <<(
        "Linha #{line_number}: ID da viagem ou data da viagem ausente."
      )

      return
    end

    trip = find_existing_trip(attributes)

    if trip.present?
      update_trip(trip, attributes, line_number)
    else
      create_trip(attributes, line_number)
    end
  end

  # =========================================================
  # IDENTIFICAÇÃO DO REGISTRO
  # =========================================================

  def find_existing_trip(attributes)
    LongTrip.find_by(
      travel_request_id: attributes[:travel_request_id],
      traveler_name: attributes[:traveler_name],
      travel_date: attributes[:travel_date],
      origin_city: attributes[:origin_city],
      destination_city: attributes[:destination_city]
    )
  end

  # =========================================================
  # CREATE / UPDATE
  # =========================================================

  def create_trip(attributes, line_number)
    trip = LongTrip.new(attributes)

    if trip.save
      @imported_count += 1
    else
      errors <<(
        "Linha #{line_number}: #{trip.errors.full_messages.join(', ')}"
      )
    end
  end

  def update_trip(trip, attributes, line_number)
    if trip.update(attributes)
      @updated_count += 1
    else
      errors <<(
        "Linha #{line_number}: #{trip.errors.full_messages.join(', ')}"
      )
    end
  end

  # =========================================================
  # CONVERSÃO DAS COLUNAS
  # =========================================================

  def build_attributes(row)
    {
      travel_request_id:
        integer_value(row["ID da viagem"]),

      traveler_name:
        clean_text(row["Nome do viajante"]),

      traveler_sector:
        clean_text(row["Setor do viajante"]),

      travel_reason:
        clean_text(row["Motivo da viagem"]),

      purchase_date:
        date_value(row["Data da compra"]),

      travel_date:
        date_value(row["Data da viagem"]),

      transport_mode:
        clean_text(row["Meio de transporte"]),

      origin_city:
        clean_text(row["Cidade origem"]),

      origin_state:
        clean_text(row["Estado origem"]),

      origin_terminal:
        clean_text(row["Nome do aeroporto ou rodoviária"]),

      destination_city:
        clean_text(row["Cidade destino"]),

      destination_state:
        clean_text(row["Estado destino"]),

      destination_terminal:
        destination_terminal(row),

      transport_company:
        clean_text(row["Nome da empresa de transporte"]),

      mileage:
        numeric_value(row["Quilometragem"]),

      policy_compliant:
        boolean_value(row["Cumpriu política?"]),

      non_compliance_reason:
        clean_text(row["Motivo do não-cumprimento"]),

      canceled:
        boolean_value(row["Passagem foi cancelada?"]),

      purchase_value_brl:
        money_value(row["Valor da compra (R$)"]),

      purchase_value_points:
        numeric_value(row["Valor da compra (Pontos)"]),

      extra_fees_brl:
        money_value(row["Taxas extras (R$)"]),

      refund_value_brl:
        money_value(row["Valor Reembolso (R$)"]),

      refund_value_points:
        numeric_value(row["Valor Reembolso (Pontos)"])
    }
  end

  # =========================================================
  # TERMINAIS
  # =========================================================

  def destination_terminal(row)
    #
    # O CSV possui duas colunas com o mesmo cabeçalho:
    #
    # Nome do aeroporto ou rodoviária
    #
    # A primeira é origem e a segunda é destino.
    #
    # CSV::Row permite acessar pelo índice.
    #

    headers = row.headers

    positions =
      headers.each_index.select do |index|
        headers[index] == "Nome do aeroporto ou rodoviária"
      end

    return nil if positions.size < 2

    clean_text(row.fields[positions[1]])
  end

  # =========================================================
  # VALIDAÇÃO
  # =========================================================

  def blank_row?(row)
    row.fields.all? do |value|
      value.to_s.strip.blank?
    end
  end

  def valid_minimum_data?(attributes)
    attributes[:travel_request_id].present? &&
      attributes[:travel_date].present?
  end

  def skip_row
    @skipped_count += 1
  end

  # =========================================================
  # CONVERSORES
  # =========================================================

  def clean_text(value)
    text = value.to_s.strip

    text.presence
  end

  def integer_value(value)
    return nil if value.blank?

    value
      .to_s
      .strip
      .sub(",", ".")
      .to_f
      .to_i
  end

  def numeric_value(value)
    return 0 if value.blank?

    normalize_number(value).to_f
  end

  def money_value(value)
    return 0 if value.blank?

    normalize_number(value).to_d
  end

  def normalize_number(value)
    value
      .to_s
      .strip
      .gsub("R$", "")
      .gsub(/\s+/, "")
      .gsub(".", "")
      .gsub(",", ".")
  end

  def date_value(value)
    return nil if value.blank?

    Date.strptime(
      value.to_s.strip,
      "%d/%m/%Y"
    )
  rescue ArgumentError
    nil
  end

  def boolean_value(value)
    normalized =
      value
        .to_s
        .strip
        .downcase
        .unicode_normalize(:nfd)
        .gsub(/\p{Mn}/, "")

    case normalized
    when "sim", "s", "true", "1"
      true

    when "nao", "n", "false", "0"
      false

    else
      nil
    end
  end
end