puts "ENEM — VALIDAÇÃO PÓS-IMPORTAÇÃO"
puts "=" * 70

puts "Total: #{EnemStateResult.count}"
puts "Anos: #{EnemStateResult.distinct.order(:year).pluck(:year).inspect}"
puts "Dependências: #{EnemStateResult.distinct.order(:administrative_dependency).pluck(:administrative_dependency).inspect}"
puts "Geografias: #{EnemStateResult.distinct.count(:state_code)}"

puts
puts "Registros por ano:"
EnemStateResult.group(:year).order(:year).count.each do |year, count|
  puts "  #{year}: #{count}"
end

puts
puts "Exemplo — Brasil / Estadual / 2025:"
record = EnemStateResult.find_by(
  year: 2025,
  state_code: "Brasil",
  administrative_dependency: "Estadual"
)

if record
  puts({
    registered_count: record.registered_count,
    participation_both_days_pct: record.participation_both_days_pct,
    human_sciences_average: record.human_sciences_average,
    mathematics_average: record.mathematics_average,
    essay_average: record.essay_average,
    general_average: record.general_average,
    essay_competency_1_average: record.essay_competency_1_average,
    essays_count: record.essays_count,
    essays_ok_pct: record.essays_ok_pct
  }.inspect)
else
  puts "Registro não encontrado."
end

puts
duplicates =
  EnemStateResult
    .group(:year, :state_code, :administrative_dependency)
    .having("COUNT(*) > 1")
    .count

puts "Duplicidades: #{duplicates.size}"
