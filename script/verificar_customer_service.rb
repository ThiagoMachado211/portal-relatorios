EXPECTED = {
  [2026, 3] => [0, 0, 0, 673, 1834, 0, nil, nil, 26_833],
  [2026, 4] => [390, 383, 321, 839, 3273, 84, 94, 6_968, 55_144],
  [2026, 5] => [561, 539, 408, 337, 1445, 312, 6_812, 20_718, 65_686],
  [2026, 6] => [285, 279, 216, 169, 595, 344, 5_741, 9_567, 30_872],
  [2026, 7] => [160, 150, 104, 78, 371, 157, 7_085, 13_869, 40_512],
  [2026, 8] => [386, 372, 296, 234, 633, 225, 4_187, 5_278, 27_670],
  [2026, 9] => [335, 327, 262, 205, 409, 160, 1_255, 2_658, 21_284]
}.freeze

FIELDS = %i[
  output_count
  responses_count
  first_responses_count
  fcr_tickets_count
  closed_tickets_count
  reopened_tickets_count
  avg_first_response_seconds
  avg_response_seconds
  avg_resolution_seconds
].freeze

def format_duration(seconds)
  return "—" if seconds.nil?

  format("%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
end

puts "=" * 72
puts " ATENDIMENTO AO CLIENTE — AUDITORIA DA IMPORTAÇÃO"
puts "=" * 72

records = CustomerServiceMonthlyResult.chronological.to_a
errors = []

EXPECTED.each do |period, expected_values|
  year, month = period
  record = records.find { |item| item.year == year && item.month == month }

  unless record
    errors << "#{year}-#{format('%02d', month)}: registro ausente"
    next
  end

  actual_values = FIELDS.map { |field| record.public_send(field) }

  FIELDS.zip(expected_values, actual_values).each do |field, expected, actual|
    next if expected == actual

    errors << "#{record.month_label} | #{field}: esperado=#{expected.inspect}, banco=#{actual.inspect}"
  end

  puts format(
    "%-6s | respostas=%4d | fechados=%4d | 1ª resp=%s | resp=%s | resolução=%s",
    record.month_label,
    record.responses_count,
    record.closed_tickets_count,
    format_duration(record.avg_first_response_seconds),
    format_duration(record.avg_response_seconds),
    format_duration(record.avg_resolution_seconds)
  )
end

extra_periods = records.map { |r| [r.year, r.month] } - EXPECTED.keys
extra_periods.each { |period| errors << "Registro inesperado no banco: #{period.inspect}" }

puts
if errors.empty?
  puts "OK — 7 meses conferidos e todos os valores coincidem com a auditoria."
else
  puts "ERRO — foram encontradas #{errors.size} divergências:"
  errors.each { |error| puts "- #{error}" }
  exit 1
end
