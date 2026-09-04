puts "ENEM — DASHBOARD COMPLETO — VERIFICAÇÃO"
puts "=" * 72

service = Enem::StatesDashboardData.new(
  year: 2025,
  state_code: "Brasil",
  dependency: "Estadual",
  view: "overview",
  evolution_metric: "general_average",
  ranking_metric: "general_average"
).call

puts "View padrão: #{service[:current_view]}"
puts "Registro encontrado: #{service[:record].present?}"
puts "Anos disponíveis: #{service[:filter_options][:years].inspect}"
puts "Geografias: #{service[:filter_options][:states].size}"
puts "Dependências: #{service[:filter_options][:dependencies].inspect}"
puts "KPIs: #{service[:kpis].keys.inspect}"
puts "Participação: #{service[:participation].size} indicadores"
puts "Desempenho: #{service[:performance].size} indicadores"
puts "Competências: #{service[:competencies].size}"
puts "Status de Redação: #{service[:essay_statuses].size}"
puts "Pontos da evolução: #{service[:evolution][:labels].size}"
puts "Estados no ranking: #{service[:ranking][:items].size}"
puts

errors = []
errors << "registro Brasil/Estadual/2025 não encontrado" unless service[:record].present?
errors << "esperados 10 anos na evolução" unless service[:evolution][:labels].size == 10
errors << "esperadas 5 competências" unless service[:competencies].size == 5
errors << "esperados 9 status" unless service[:essay_statuses].size == 9
errors << "ranking vazio" if service[:ranking][:items].empty?

if errors.empty?
  puts "OK — estrutura do dashboard validada."
else
  puts "ATENÇÃO:"
  errors.each { |error| puts "- #{error}" }
  exit 1
end
