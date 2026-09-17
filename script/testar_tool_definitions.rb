puts
puts "TESTE — FERRAMENTAS DISPONÍVEIS POR PERFIL"
puts "=" * 70

roles = [
  :client,
  :manager,
  :admin
]

roles.each do |role|
  user =
    User.new(
      name: "Teste",
      email: "#{role}@teste.com",
      user_type: role
    )

  definitions =
    Ai::ToolRegistry.definitions(
      user: user
    )

  names =
    definitions.map do |definition|
      definition[:name] ||
        definition["name"]
    end

  puts
  puts "#{role.to_s.upcase}"
  puts "-" * 70
  puts "Quantidade: #{names.length}"

  names.each do |name|
    puts "  - #{name}"
  end
end

puts
puts "=" * 70
puts "TESTE CONCLUÍDO."
puts "=" * 70