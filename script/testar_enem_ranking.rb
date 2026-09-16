puts
puts "TESTE — RANKING ENEM"
puts "=" * 70


puts
puts "1. TOP 5 — MATEMÁTICA — ESTADUAL — 2025"
puts "-" * 70

begin
  ranking =
    Ai::Tools::EnemRanking.call(
      year: 2025,
      administrative_dependency: "Estadual",
      metric: "mathematics_average",
      direction: "highest",
      limit: 5
    )

  pp ranking

  if ranking[:results].any? do |item|
       item[:state_code] == "Brasil"
     end

    puts "ERRO — Brasil apareceu no ranking estadual."
    exit 1
  end

  puts
  puts "OK — Brasil não participa do ranking."

rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "2. BOTTOM 5 — PARTICIPAÇÃO DIA 1 — 2025"
puts "-" * 70

begin
  ranking =
    Ai::Tools::EnemRanking.call(
      year: 2025,
      administrative_dependency: "Estadual",
      metric: "participation_day1_pct",
      direction: "lowest",
      limit: 5
    )

  pp ranking

rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "3. RANKING COMPLETO — 27 UFs"
puts "-" * 70

begin
  ranking =
    Ai::Tools::EnemRanking.call(
      year: 2025,
      administrative_dependency: "Estadual",
      metric: "essay_average",
      direction: "highest",
      limit: 27
    )

  pp ranking

  puts
  puts "Estados retornados: #{ranking[:results].length}"
  puts "Estados disponíveis: #{ranking[:total_states_available]}"

rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "4. SEGURANÇA — INDICADOR INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::EnemRanking.call(
    year: 2025,
    administrative_dependency: "Estadual",
    metric: "physics_average",
    direction: "highest",
    limit: 5
  )

  puts "ERRO — indicador inválido foi aceito."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — indicador inválido bloqueado."
  puts e.message
end


puts
puts "5. SEGURANÇA — DIREÇÃO INVÁLIDA"
puts "-" * 70

begin
  Ai::Tools::EnemRanking.call(
    year: 2025,
    administrative_dependency: "Estadual",
    metric: "mathematics_average",
    direction: "qualquer_coisa",
    limit: 5
  )

  puts "ERRO — direção inválida foi aceita."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — direção inválida bloqueada."
  puts e.message
end


puts
puts "6. SEGURANÇA — LIMITE INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::EnemRanking.call(
    year: 2025,
    administrative_dependency: "Estadual",
    metric: "mathematics_average",
    direction: "highest",
    limit: 100
  )

  puts "ERRO — limite inválido foi aceito."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — limite inválido bloqueado."
  puts e.message
end


puts
puts "=" * 70
puts "OK — TESTES DO RANKING ENEM CONCLUÍDOS"