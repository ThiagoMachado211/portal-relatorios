puts
puts "TESTE — FERRAMENTAS DE ATENDIMENTO AO CLIENTE"
puts "=" * 70


puts
puts "1. TÍQUETES FECHADOS — SETEMBRO/2026"
puts "-" * 70

begin
  result =
    Ai::Tools::CustomerServiceMetric.call(
      year: 2026,
      month: 9,
      metric: "closed_tickets_count"
    )

  pp result

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "2. TEMPO MÉDIO DE PRIMEIRA RESPOSTA — SETEMBRO/2026"
puts "-" * 70

begin
  result =
    Ai::Tools::CustomerServiceMetric.call(
      year: 2026,
      month: 9,
      metric: "avg_first_response_seconds"
    )

  pp result

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "3. TEMPO MÉDIO DE RESOLUÇÃO — SETEMBRO/2026"
puts "-" * 70

begin
  result =
    Ai::Tools::CustomerServiceMetric.call(
      year: 2026,
      month: 9,
      metric: "avg_resolution_seconds"
    )

  pp result

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "4. EVOLUÇÃO — TÍQUETES FCR — MARÇO A SETEMBRO/2026"
puts "-" * 70

begin
  result =
    Ai::Tools::CustomerServiceEvolution.call(
      metric: "fcr_tickets_count",
      start_year: 2026,
      start_month: 3,
      end_year: 2026,
      end_month: 9
    )

  pp result

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "5. EVOLUÇÃO — TEMPO DE RESOLUÇÃO — MARÇO A SETEMBRO/2026"
puts "-" * 70

begin
  result =
    Ai::Tools::CustomerServiceEvolution.call(
      metric: "avg_resolution_seconds",
      start_year: 2026,
      start_month: 3,
      end_year: 2026,
      end_month: 9
    )

  pp result

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "ERRO: #{e.message}"
  exit 1
end


puts
puts "6. SEGURANÇA — INDICADOR INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::CustomerServiceMetric.call(
    year: 2026,
    month: 9,
    metric: "source_filename"
  )

  puts "ERRO — indicador inválido foi aceito."
  exit 1

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "OK — indicador inválido bloqueado."
  puts e.message
end


puts
puts "7. SEGURANÇA — MÊS INVÁLIDO"
puts "-" * 70

begin
  Ai::Tools::CustomerServiceMetric.call(
    year: 2026,
    month: 13,
    metric: "closed_tickets_count"
  )

  puts "ERRO — mês inválido foi aceito."
  exit 1

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "OK — mês inválido bloqueado."
  puts e.message
end


puts
puts "8. SEGURANÇA — PERÍODO INVERTIDO"
puts "-" * 70

begin
  Ai::Tools::CustomerServiceEvolution.call(
    metric: "closed_tickets_count",
    start_year: 2026,
    start_month: 9,
    end_year: 2026,
    end_month: 3
  )

  puts "ERRO — período inválido foi aceito."
  exit 1

rescue Ai::Tools::CustomerServiceBase::Error => e
  puts "OK — período inválido bloqueado."
  puts e.message
end


puts
puts "=" * 70
puts "OK — TESTES DE ATENDIMENTO AO CLIENTE CONCLUÍDOS"