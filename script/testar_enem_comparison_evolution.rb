puts
puts "TESTE — COMPARAÇÃO E EVOLUÇÃO ENEM"
puts "=" * 70

puts
puts "1. COMPARAÇÃO — MATEMÁTICA — 2025"
puts "-" * 70

begin
  comparison =
    Ai::Tools::EnemComparison.call(
      year: 2025,
      state_codes: [
        "MG",
        "SP",
        "BA"
      ],
      administrative_dependency:
        "Estadual",
      metric:
        "mathematics_average"
    )

  pp comparison
rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end

puts
puts "2. COMPARAÇÃO — NORMALIZAÇÃO DE GEOGRAFIAS"
puts "-" * 70

begin
  comparison =
    Ai::Tools::EnemComparison.call(
      year: 2025,
      state_codes: [
        "mg",
        "sp",
        "brasil"
      ],
      administrative_dependency:
        "estadual",
      metric:
        "essay_average"
    )

  pp comparison
rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end

puts
puts "3. EVOLUÇÃO — REDAÇÃO — MG — 2016 A 2025"
puts "-" * 70

begin
  evolution =
    Ai::Tools::EnemEvolution.call(
      state_code: "MG",
      administrative_dependency:
        "Estadual",
      metric:
        "essay_average",
      start_year: 2016,
      end_year: 2025
    )

  pp evolution
rescue Ai::Tools::EnemBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end

puts
puts "4. TESTE DE SEGURANÇA — INDICADOR INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::EnemComparison.call(
    year: 2025,
    state_codes: ["MG", "SP"],
    administrative_dependency:
      "Estadual",
    metric:
      "physics_average"
  )

  puts "ERRO — indicador inválido foi aceito."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — indicador inválido bloqueado."
  puts e.message
end

puts
puts "5. TESTE DE SEGURANÇA — GEOGRAFIA INVÁLIDA"
puts "-" * 70

begin
  Ai::Tools::EnemEvolution.call(
    state_code: "XX",
    administrative_dependency:
      "Estadual",
    metric:
      "mathematics_average",
    start_year: 2020,
    end_year: 2025
  )

  puts "ERRO — geografia inválida foi aceita."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — geografia inválida bloqueada."
  puts e.message
end

puts
puts "6. TESTE DE SEGURANÇA — INTERVALO INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::EnemEvolution.call(
    state_code: "MG",
    administrative_dependency:
      "Estadual",
    metric:
      "mathematics_average",
    start_year: 2025,
    end_year: 2020
  )

  puts "ERRO — intervalo inválido foi aceito."
  exit 1

rescue Ai::Tools::EnemBase::Error => e
  puts "OK — intervalo inválido bloqueado."
  puts e.message
end

puts
puts "=" * 70
puts "OK — TESTES DE COMPARAÇÃO E EVOLUÇÃO CONCLUÍDOS"