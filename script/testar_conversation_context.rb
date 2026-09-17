puts
puts "TESTE — CONTEXTO DA CONVERSA"
puts "=" * 60

history = [
  {
    "role" => "user",
    "content" =>
      "Qual foi a média de Matemática de MG em 2025 na rede estadual?"
  },
  {
    "role" => "assistant",
    "content" =>
      "A média de Matemática de MG em 2025 foi 496,91."
  }
]

result =
  Ai::ConversationContext.build(
    question: "E de SP?",
    history: history
  )

puts result

puts
puts "=" * 60

unless result.include?("E de SP?")
  raise "ERRO — pergunta atual ausente."
end

unless result.include?("MG")
  raise "ERRO — histórico ausente."
end

unless result.include?("2025")
  raise "ERRO — ano do histórico ausente."
end

unless result.include?("Estadual") ||
       result.include?("estadual")
  raise "ERRO — dependência ausente."
end

puts
puts "OK — CONTEXTO DA CONVERSA CONSTRUÍDO."
puts "=" * 60