puts
puts "TESTE — PERMISSÕES DO CHATBOT"
puts "=" * 60

client =
  User.new(
    name: "Cliente Teste",
    email: "client-test@example.com",
    user_type: :client
  )

manager =
  User.new(
    name: "Manager Teste",
    email: "manager-test@example.com",
    user_type: :manager
  )

admin =
  User.new(
    name: "Admin Teste",
    email: "admin-test@example.com",
    user_type: :admin
  )

def check(user, tool_name, expected)
  result =
    Ai::ToolAuthorization.allowed?(
      user: user,
      tool_name: tool_name
    )

  status =
    result == expected ? "OK" : "ERRO"

  puts(
    "#{status} | " \
    "#{user.user_type.ljust(7)} | " \
    "#{tool_name.ljust(30)} | " \
    "#{result}"
  )

  unless result == expected
    raise(
      "Permissão inesperada para " \
      "#{user.user_type} / #{tool_name}"
    )
  end
end

puts
puts "CLIENT"
puts "-" * 60

check(client, "enem_metric", true)
check(client, "enem_comparison", true)
check(client, "enem_evolution", true)
check(client, "enem_ranking", true)

check(
  client,
  "customer_service_metric",
  false
)

check(
  client,
  "customer_service_evolution",
  false
)

puts
puts "MANAGER"
puts "-" * 60

Ai::ToolRegistry.tool_names.each do |tool_name|
  check(
    manager,
    tool_name,
    true
  )
end

puts
puts "ADMIN"
puts "-" * 60

Ai::ToolRegistry.tool_names.each do |tool_name|
  check(
    admin,
    tool_name,
    true
  )
end

puts
puts "FERRAMENTA INEXISTENTE"
puts "-" * 60

check(
  admin,
  "executar_sql",
  false
)

puts
puts "=" * 60
puts "OK — PERMISSÕES DO CHATBOT VALIDADAS."
puts "=" * 60