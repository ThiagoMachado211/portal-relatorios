require "csv"
require "bigdecimal"
require "date"

puts
puts "=" * 70
puts "GESTÃO DE VIAGENS — CARGA COMPLETA"
puts "=" * 70
puts

# ============================================================
# ARQUIVO
# ============================================================

file_path =
  ARGV[0].presence ||
  Rails.root.join(
    "tmp",
    "imports",
    "GESTAO_VIAGENS - TRECHOS_LONGOS_EXPORT.csv"
  ).to_s

unless File.exist?(file_path)
  abort <<~MSG

    ERRO: arquivo não encontrado.

    Caminho procurado:
    #{file_path}

  MSG
end

puts "Arquivo:"
puts file_path
puts

# ============================================================
# CABEÇALHOS ESPERADOS
# ============================================================

required_headers = [
  "ID da viagem",
  "Nome do viajante",
  "Setor do viajante",
  "Motivo da viagem",
  "Data da compra",
  "Data da viagem",
  "Meio de transporte",
  "Cidade origem",
  "Estado origem",
  "Nome do aeroporto ou rodoviária (Origem)",
  "Cidade destino",
  "Estado destino",
  "Nome do aeroporto ou rodoviária (Destino)",
  "Nome da empresa de transporte",
  "Quilometragem",
  "Cumpriu política?",
  "Motivo do não-cumprimento",
  "Passagem foi cancelada?",
  "Valor da compra (R$)",
  "Valor da compra (Pontos)",
  "Taxas extras (R$)",
  "Valor Reembolso (R$)",
  "Valor Reembolso (Pontos)"
].freeze

# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

def clean_text(value)
  text = value.to_s.strip
  text.empty? ? nil : text
end

def parse_date(value)
  return nil if value.to_s.strip.empty?

  text = value.to_s.strip

  [
    "%d/%m/%Y",
    "%d/%m/%y"
  ].each do |format|
    begin
      return Date.strptime(text, format)
    rescue ArgumentError
      next
    end
  end

  raise ArgumentError, "data inválida: #{value.inspect}"
end

def normalize_number(value)
  text =
    value
      .to_s
      .strip
      .gsub("R$", "")
      .gsub(/\s+/, "")

  return nil if text.empty?
  return nil if ["-", "–", "—"].include?(text)

  if text.include?(",")
    text
      .gsub(".", "")
      .gsub(",", ".")
  else
    # Neste CSV, valores como 120.000 nos campos de pontos
    # representam 120000, e não 120.0.
    if text.match?(/\A-?\d{1,3}(\.\d{3})+\z/)
      text.gsub(".", "")
    else
      text
    end
  end
end

def parse_decimal(value)
  normalized = normalize_number(value)

  return nil if normalized.nil?

  BigDecimal(normalized)
end

def parse_number(value)
  normalized = normalize_number(value)

  return nil if normalized.nil?

  normalized.to_f
end

def parse_integer(value)
  normalized = normalize_number(value)

  return nil if normalized.nil?

  normalized.to_f.to_i
end

def parse_boolean(value)
  return nil if value.to_s.strip.empty?

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
    raise ArgumentError, "booleano inválido: #{value.inspect}"
  end
end

# ============================================================
# LEITURA
# ============================================================

raw_content =
  File
    .binread(file_path)
    .force_encoding("UTF-8")
    .sub(/\A\xEF\xBB\xBF/, "")
    .gsub("\r\n", "\n")
    .gsub("\r", "\n")

rows =
  CSV.parse(
    raw_content,
    headers: true,
    liberal_parsing: true,
    row_sep: "\n"
  )

headers = rows.headers

missing_headers =
  required_headers.reject do |header|
    headers.include?(header)
  end

if missing_headers.any?
  puts "ERRO: colunas obrigatórias ausentes:"
  puts

  missing_headers.each do |header|
    puts "  - #{header}"
  end

  abort
end

puts "Linhas encontradas no CSV: #{rows.size}"
puts

# ============================================================
# CONVERSÃO
# ============================================================

records = []
errors = []

rows.each_with_index do |row, index|
  csv_line = index + 2

  begin
    attributes = {
      travel_request_id:
        parse_integer(row["ID da viagem"]),

      traveler_name:
        clean_text(row["Nome do viajante"]),

      traveler_sector:
        clean_text(row["Setor do viajante"]),

      travel_reason:
        clean_text(row["Motivo da viagem"]),

      purchase_date:
        parse_date(row["Data da compra"]),

      travel_date:
        parse_date(row["Data da viagem"]),

      transport_mode:
        clean_text(row["Meio de transporte"]),

      origin_city:
        clean_text(row["Cidade origem"]),

      origin_state:
        clean_text(row["Estado origem"]),

      origin_terminal:
        clean_text(
          row["Nome do aeroporto ou rodoviária (Origem)"]
        ),

      destination_city:
        clean_text(row["Cidade destino"]),

      destination_state:
        clean_text(row["Estado destino"]),

      destination_terminal:
        clean_text(
          row["Nome do aeroporto ou rodoviária (Destino)"]
        ),

      transport_company:
        clean_text(
          row["Nome da empresa de transporte"]
        ),

      mileage:
        parse_number(row["Quilometragem"]),

      policy_compliant:
        parse_boolean(row["Cumpriu política?"]),

      non_compliance_reason:
        clean_text(
          row["Motivo do não-cumprimento"]
        ),

      canceled:
        parse_boolean(
          row["Passagem foi cancelada?"]
        ),

      purchase_value_brl:
        parse_decimal(
          row["Valor da compra (R$)"]
        ),

      purchase_value_points:
        parse_number(
          row["Valor da compra (Pontos)"]
        ),

      extra_fees_brl:
        parse_decimal(
          row["Taxas extras (R$)"]
        ),

      refund_value_brl:
        parse_decimal(
          row["Valor Reembolso (R$)"]
        ),

      refund_value_points:
        parse_number(
          row["Valor Reembolso (Pontos)"]
        )
    }

    # --------------------------------------------------------
    # Campos essenciais
    # --------------------------------------------------------

    essential_fields = {
      travel_request_id: "ID da viagem",
      traveler_name: "Nome do viajante",
      traveler_sector: "Setor do viajante",
      travel_reason: "Motivo da viagem",
      purchase_date: "Data da compra",
      travel_date: "Data da viagem",
      transport_mode: "Meio de transporte",
      origin_city: "Cidade origem",
      origin_state: "Estado origem",
      origin_terminal: "Terminal de origem",
      destination_city: "Cidade destino",
      destination_state: "Estado destino",
      policy_compliant: "Cumpriu política?",
      canceled: "Passagem cancelada?"
    }

    missing =
      essential_fields.filter_map do |field, label|
        value = attributes[field]

        is_missing =
          value.nil? ||
          (
            value.is_a?(String) &&
            value.strip.empty?
          )

        label if is_missing
      end

    if missing.any?
      errors <<(
        "Linha #{csv_line}: campos essenciais ausentes: " \
        "#{missing.join(', ')}"
      )

      next
    end

    # Validação do próprio model
    trip = LongTrip.new(attributes)

    unless trip.valid?
      errors <<(
        "Linha #{csv_line}: " \
        "#{trip.errors.full_messages.join(', ')}"
      )

      next
    end

    records << attributes

  rescue StandardError => e
    errors <<(
      "Linha #{csv_line}: #{e.message}"
    )
  end
end

# ============================================================
# RELATÓRIO DE PRÉ-VALIDAÇÃO
# ============================================================

puts "Registros preparados: #{records.size}"
puts "Problemas encontrados: #{errors.size}"
puts

if errors.any?
  puts "A IMPORTAÇÃO FOI CANCELADA."
  puts "Nenhum registro do banco foi alterado."
  puts
  puts "Erros:"
  puts

  errors.each do |error|
    puts "  - #{error}"
  end

  abort
end

if records.empty?
  abort "Nenhum registro válido encontrado."
end

# ============================================================
# CONFIRMAÇÃO
# ============================================================

puts "Base atual no PostgreSQL: #{LongTrip.count} registros"
puts
puts "A base atual será SUBSTITUÍDA integralmente."
puts

# Quando usamos Rails Runner não queremos exigir interação
# em produção, então a confirmação é feita por variável.
#
# Para executar:
#
# CONFIRM_IMPORT=YES ruby bin/rails runner ...
#

unless ENV["CONFIRM_IMPORT"] == "YES"
  puts "MODO DE VALIDAÇÃO."
  puts
  puts "Nada foi gravado."
  puts
  puts "Para confirmar a carga, execute novamente com:"
  puts
  puts '  $env:CONFIRM_IMPORT="YES"'
  puts '  ruby bin/rails runner script/import_long_trips.rb'
  puts
  exit
end

# ============================================================
# IMPORTAÇÃO TRANSACIONAL
# ============================================================

old_count = LongTrip.count

ActiveRecord::Base.transaction do
  LongTrip.delete_all

  records.each do |attributes|
    LongTrip.create!(attributes)
  end

  unless LongTrip.count == records.size
    raise ActiveRecord::Rollback,
          "Quantidade final divergente."
  end
end

# ============================================================
# AUDITORIA FINAL
# ============================================================

final_count = LongTrip.count

min_date = LongTrip.minimum(:travel_date)
max_date = LongTrip.maximum(:travel_date)

monthly =
  LongTrip
    .where.not(travel_date: nil)
    .group(
      "EXTRACT(YEAR FROM travel_date)",
      "EXTRACT(MONTH FROM travel_date)"
    )
    .order(
      Arel.sql(
        "EXTRACT(YEAR FROM travel_date), " \
        "EXTRACT(MONTH FROM travel_date)"
      )
    )
    .count

month_names = {
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

puts
puts "=" * 70
puts "IMPORTAÇÃO CONCLUÍDA"
puts "=" * 70
puts
puts "Registros anteriores: #{old_count}"
puts "Registros importados: #{final_count}"
puts
puts "Primeira data de viagem: #{min_date&.strftime('%d/%m/%Y')}"
puts "Última data de viagem:   #{max_date&.strftime('%d/%m/%Y')}"
puts
puts "Distribuição mensal:"
puts

monthly.each do |(year, month), count|
  month = month.to_i

  puts(
    "  #{month_names[month]} #{year.to_i}: " \
    "#{count}"
  )
end

puts
puts "=" * 70
puts