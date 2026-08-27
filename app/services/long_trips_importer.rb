require "csv"
require "bigdecimal"

class LongTripsImporter
  attr_reader :imported_count,
              :deleted_count,
              :skipped_count,
              :errors

  def initialize(file_path)
    @file_path = file_path

    @imported_count = 0
    @deleted_count = 0
    @skipped_count = 0
    @errors = []
  end

  def call
    rows = read_rows

    return self if errors.any?

    attributes_list = prepare_records(rows)

    return self if errors.any?
    return self if attributes_list.empty?

    validate_records(attributes_list)

    return self if errors.any?

    replace_database(attributes_list)

    self
  rescue StandardError => e
    errors << "Erro geral na importação: #{e.message}"
    self
  end

  private

  # =========================================================
  # LEITURA DO CSV
  # =========================================================

  def read_rows
    raw_content = File.binread(@file_path)

    utf8_content =
      raw_content
        .force_encoding("UTF-8")
        .sub(/\A\xEF\xBB\xBF/, "")
        .gsub("\r\n", "\n")
        .gsub("\r", "\n")

    CSV.parse(
      utf8_content,
      headers: true,
      liberal_parsing: true,
      row_sep: "\n"
    )
  rescue CSV::MalformedCSVError => e
    errors << "CSV inválido: #{e.message}"
    []
  rescue StandardError => e
    errors << "Não foi possível ler o arquivo: #{e.message}"
    []
  end

  # =========================================================
  # PREPARAÇÃO
  # =========================================================

  def prepare_records(rows)
    records = []

    rows.each_with_index do |row, index|
      line_number = index + 2

      if blank_row?(row)
        @skipped_count += 1
        next
      end

      attributes = build_attributes(row)

      unless minimum_data_present?(attributes)
        errors <<(
          "Linha #{line_number}: ID da viagem, nome do viajante, " \
          "data da viagem ou meio de transporte ausente."
        )

        next
      end

      records << {
        line_number: line_number,
        attributes: attributes
      }
    end

    records
  end

  # =========================================================
  # VALIDAÇÃO ANTES DE APAGAR A BASE
  # =========================================================

  def validate_records(records)
    records.each do |record_data|
      trip = LongTrip.new(
        record_data[:attributes]
      )

      next if trip.valid?

      errors <<(
        "Linha #{record_data[:line_number]}: " \
        "#{trip.errors.full_messages.join(', ')}"
      )
    end
  end

  # =========================================================
  # SUBSTITUIÇÃO TRANSACIONAL
  # =========================================================

  def replace_database(records)
    ActiveRecord::Base.transaction do
      @deleted_count = LongTrip.count

      LongTrip.delete_all

      records.each do |record_data|
        LongTrip.create!(
          record_data[:attributes]
        )

        @imported_count += 1
      end
    end
  rescue StandardError => e
    @imported_count = 0
    @deleted_count = 0

    errors <<(
      "A sincronização foi cancelada e a base anterior foi preservada. " \
      "Motivo: #{e.message}"
    )
  end

  # =========================================================
  # MAPEAMENTO
  # =========================================================

  def build_attributes(row)
    {
      travel_request_id:
        integer_value(
          row["ID da viagem"]
        ),

      traveler_name:
        clean_text(
          row["Nome do viajante"]
        ),

      traveler_sector:
        clean_text(
          row["Setor do viajante"]
        ),

      travel_reason:
        clean_text(
          row["Motivo da viagem"]
        ),

      purchase_date:
        date_value(
          row["Data da compra"]
        ),

      travel_date:
        date_value(
          row["Data da viagem"]
        ),

      transport_mode:
        clean_text(
          row["Meio de transporte"]
        ),

      origin_city:
        clean_text(
          row["Cidade origem"]
        ),

      origin_state:
        clean_text(
          row["Estado origem"]
        ),

      origin_terminal:
        duplicated_header_value(
          row,
          "Nome do aeroporto ou rodoviária",
          0
        ),

      destination_city:
        clean_text(
          row["Cidade destino"]
        ),

      destination_state:
        clean_text(
          row["Estado destino"]
        ),

      destination_terminal:
        duplicated_header_value(
          row,
          "Nome do aeroporto ou rodoviária",
          1
        ),

      transport_company:
        clean_text(
          row["Nome da empresa de transporte"]
        ),

      mileage:
        numeric_value(
          row["Quilometragem"]
        ),

      policy_compliant:
        boolean_value(
          row["Cumpriu política?"]
        ),

      non_compliance_reason:
        clean_text(
          row["Motivo do não-cumprimento"]
        ),

      canceled:
        boolean_value(
          row["Passagem foi cancelada?"]
        ),

      purchase_value_brl:
        decimal_value(
          row["Valor da compra (R$)"]
        ),

      purchase_value_points:
        numeric_value(
          row["Valor da compra (Pontos)"]
        ),

      extra_fees_brl:
        decimal_value(
          row["Taxas extras (R$)"]
        ),

      refund_value_brl:
        decimal_value(
          row["Valor Reembolso (R$)"]
        ),

      refund_value_points:
        numeric_value(
          row["Valor Reembolso (Pontos)"]
        )
    }
  end

  # =========================================================
  # CABEÇALHOS DUPLICADOS
  # =========================================================

  def duplicated_header_value(row, header_name, occurrence)
    indexes =
      row.headers
         .each_index
         .select do |index|
           normalize_header(
             row.headers[index]
           ) == normalize_header(header_name)
         end

    index = indexes[occurrence]

    return nil if index.nil?

    clean_text(
      row.fields[index]
    )
  end

  def normalize_header(value)
    value
      .to_s
      .sub(/\.\d+\z/, "")
      .strip
  end

  # =========================================================
  # VALIDAÇÃO MÍNIMA
  # =========================================================

  def minimum_data_present?(attributes)
    attributes[:travel_request_id].present? &&
      attributes[:traveler_name].present? &&
      attributes[:travel_date].present? &&
      attributes[:transport_mode].present?
  end

  def blank_row?(row)
    row.fields.all? do |value|
      value.to_s.strip.blank?
    end
  end

  # =========================================================
  # TEXTO
  # =========================================================

  def clean_text(value)
    text =
      value
        .to_s
        .strip

    text.presence
  end

  # =========================================================
  # DATAS
  # =========================================================

  def date_value(value)
    return nil if value.blank?

    text = value.to_s.strip

    Date.strptime(
      text,
      "%d/%m/%Y"
    )
  rescue ArgumentError
    nil
  end

  # =========================================================
  # NÚMEROS
  # =========================================================

  def integer_value(value)
    return nil if value.blank?

    normalize_number(value)
      .to_f
      .to_i
  end

  def numeric_value(value)
    return 0 if value.blank?

    normalize_number(value).to_f
  end

  def decimal_value(value)
    return BigDecimal("0") if value.blank?

    BigDecimal(
      normalize_number(value)
    )
  rescue ArgumentError
    BigDecimal("0")
  end

  def normalize_number(value)
    text =
      value
        .to_s
        .strip
        .gsub("R$", "")
        .gsub(/\s+/, "")

    # Exemplo brasileiro:
    # 2.314,34 -> 2314.34

    if text.include?(",")
      text
        .gsub(".", "")
        .gsub(",", ".")
    else
      text
    end
  end

  # =========================================================
  # BOOLEANOS
  # =========================================================

  def boolean_value(value)
    return nil if value.blank?

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