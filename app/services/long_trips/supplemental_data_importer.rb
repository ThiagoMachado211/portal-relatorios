require "csv"
require "bigdecimal"

module LongTrips
  class SupplementalDataImporter
    DEFAULT_DIR = Rails.root.join("db", "import_data", "travel")

    attr_reader :directory

    def initialize(directory: DEFAULT_DIR)
      @directory = Pathname.new(directory)
    end

    def call
      ActiveRecord::Base.transaction do
        import_summaries
        import_accommodations
        import_transfers
      end

      {
        travel_summaries: TravelSummary.count,
        travel_accommodations: TravelAccommodation.count,
        travel_transfers: TravelTransfer.count
      }
    end

    private

    def import_summaries
      path = directory.join("DADOS_POR_VIAGEM.csv")
      rows = read_csv(path)
      TravelSummary.delete_all

      rows.each do |row|
        id = integer(row["ID da viagem (Interno)"])
        next if id.blank?

        TravelSummary.create!(
          travel_request_id: id,
          outbound_date: date(row["Data da ida"]),
          return_date: date(row["Data do retorno"]),
          duration_days: integer(row["Duração"]),
          long_segments_value_brl: decimal(row["Valor Total  - Trechos Longos (R$)"]),
          short_segments_value_brl: decimal(row["Valor Total - Trechos Curtos (R$)"]),
          accommodation_value_brl: decimal(row["Valor Total Hospedagem (R$)"]),
          total_value_brl: decimal(row["Valor Total da Viagem (R$)"]),
          total_value_points: decimal(row["Valor Total da Viagem (Pontos)"])
        )
      end
    end

    def import_accommodations
      path = directory.join("HOSPEDAGEM.csv")
      rows = read_csv(path)
      TravelAccommodation.delete_all

      rows.each do |row|
        id = integer(row["ID da viagem (Interno)"])
        next if id.blank?

        TravelAccommodation.create!(
          travel_request_id: id,
          traveler_name: clean(row["Nome do viajante"]),
          hotel: clean(row["Hotel"]),
          purchase_date: date(row["Data da compra"]),
          check_in_date: date(row["Data do Check-In"]),
          check_out_date: date(row["Data do Check-Out"]),
          stay_duration_days: integer(row["Duração da Estadia (Dias)"]),
          daily_rates_text: clean(row["Valores das Diárias (R$)"]),
          average_daily_rate_brl: decimal(row["Valor Médio da Diária (R$)"]),
          total_stay_value_brl: decimal(row["Valor Total da Estadia (R$)"])
        )
      end
    end

    def import_transfers
      path = directory.join("TRANSLADO.csv")
      rows = read_csv(path)
      TravelTransfer.delete_all

      rows.each do |row|
        id = integer(row["ID da viagem (Interno)"])
        travel_date = date(row["Data da viagem"])
        next if id.blank? || travel_date.blank?

        traveler = clean(row["Nome do viajante"])
        next if traveler.blank? || traveler.downcase.start_with?("defina ")

        TravelTransfer.create!(
          travel_request_id: id,
          traveler_name: traveler,
          traveler_sector: clean(row["Setor do viajante"]),
          travel_reason: clean(row["Motivo da viagem"]),
          company: clean(row["Empresa"]),
          origin: clean(row["Origem"]),
          destination: clean(row["Destino"]),
          estimated_mileage: decimal(row["Quilometragem Estimada"]),
          travel_date: travel_date,
          value_brl: decimal(row["Valor (R$)"])
        )
      end
    end

    def read_csv(path)
      raise "Arquivo não encontrado: #{path}" unless path.exist?
      CSV.read(path, headers: true, encoding: "bom|utf-8")
    end

    def clean(value)
      value.to_s.strip.presence
    end

    def integer(value)
      text = clean(value)
      return nil if text.blank?
      BigDecimal(normalize_number(text)).to_i
    rescue ArgumentError
      nil
    end

    def decimal(value)
      text = clean(value)
      return BigDecimal("0") if text.blank?
      BigDecimal(normalize_number(text))
    rescue ArgumentError
      BigDecimal("0")
    end

    def normalize_number(value)
      text = value.to_s.gsub(/R\$|\s/, "")
      if text.include?(",")
        text.gsub(".", "").tr(",", ".")
      else
        text
      end
    end

    def date(value)
      text = clean(value)
      return nil if text.blank?
      Date.strptime(text, "%d/%m/%Y")
    rescue ArgumentError
      nil
    end
  end
end
