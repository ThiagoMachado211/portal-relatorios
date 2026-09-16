puts
puts "=" * 72
puts " ATENDIMENTO AO CLIENTE — AUDITORIA DO DASHBOARD REVISADO"
puts "=" * 72
puts

expected_classifications = {
  [2026, 3] => [0, 0, 0],
  [2026, 4] => [2, 0, 49],
  [2026, 5] => [5, 5, 99],
  [2026, 6] => [2, 0, 24],
  [2026, 7] => [2, 1, 9],
  [2026, 8] => [4, 4, 110],
  [2026, 9] => [6, 3, 119]
}.freeze

errors = []

rows = CustomerServiceMonthlyResult.chronological.to_a

if rows.size != 7
  errors << "Esperados 7 meses, encontrados #{rows.size}."
end

expected_classifications.each do |(year, month), expected|
  row = rows.find { |item| item.year == year && item.month == month }

  unless row
    errors << format("Mês %02d/%d não encontrado.", month, year)
    next
  end

  actual = [
    row.ok_classifications_count,
    row.bad_classifications_count,
    row.good_classifications_count
  ]

  if actual != expected
    errors << "#{row.month_label}: classificações esperadas #{expected.inspect}, encontradas #{actual.inspect}."
  end
end

dashboard = CustomerService::DashboardData.new(view: "overview").call

expected_views = %w[
  overview
  fcr_tickets
  closed_tickets
  avg_first_response
  avg_response
  avg_resolution
  ok_classifications
  bad_classifications
  good_classifications
]

actual_views = dashboard[:navigation].keys

unless actual_views == expected_views
  errors << "Navegação incorreta: #{actual_views.inspect}"
end

if dashboard[:overview].size != 8
  errors << "Visão Geral deveria possuir 8 indicadores; possui #{dashboard[:overview].size}."
end

expected_views.drop(1).each do |view|
  data = CustomerService::DashboardData.new(view: view).call

  if data[:evolution].nil?
    errors << "#{view}: série histórica não foi gerada."
    next
  end

  if data[:evolution][:labels].size != 7 || data[:evolution][:values].size != 7
    errors << "#{view}: série histórica deveria possuir 7 meses."
  end
end

if errors.any?
  puts "ERROS ENCONTRADOS:"
  errors.each { |error| puts " - #{error}" }
  puts
  exit 1
end

rows.each do |row|
  puts "#{row.month_label.ljust(6)} | OK=#{row.ok_classifications_count.to_s.rjust(3)} | " \
       "ruins=#{row.bad_classifications_count.to_s.rjust(3)} | " \
       "boas=#{row.good_classifications_count.to_s.rjust(3)}"
end

puts
puts "OK — dashboard revisado preparado corretamente para os 8 indicadores."
