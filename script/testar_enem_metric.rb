puts
puts "TESTE — FERRAMENTA ENEM METRIC"
puts "=" * 60

tests = [
  {
    description: "Matemática — MG — Estadual — 2025",
    args: {
      year: 2025,
      state_code: "MG",
      administrative_dependency: "Estadual",
      metric: "mathematics_average"
    }
  },
  {
    description: "Participação Dia 1 — MG — Estadual — 2025",
    args: {
      year: 2025,
      state_code: "MG",
      administrative_dependency: "Estadual",
      metric: "participation_day1_pct"
    }
  },
  {
    description: "Redação — Brasil — Estadual — 2025",
    args: {
      year: 2025,
      state_code: "BRASIL",
      administrative_dependency: "Estadual",
      metric: "essay_average"
    }
  }
]

tests.each_with_index do |test, index|
  puts
  puts "#{index + 1}. #{test[:description]}"

  begin
    result =
      Ai::Tools::EnemMetric.call(
        **test[:args]
      )

    pp result
  rescue Ai::Tools::EnemMetric::Error => e
    puts "ERRO: #{e.message}"
  end
end

puts
puts "=" * 60

puts
puts "TESTE DE SEGURANÇA"

begin
  Ai::Tools::EnemMetric.call(
    year: 2025,
    state_code: "MG",
    administrative_dependency: "Estadual",
    metric: "physics_average"
  )

  puts "ERRO — indicador inválido foi aceito."
  exit 1

rescue Ai::Tools::EnemMetric::Error => e
  puts "OK — indicador inválido bloqueado."
  puts e.message
end

puts
puts "=" * 60
puts "FIM DO TESTE"