puts
puts "TESTE DE CONEXÃO — OPENAI"
puts "=" * 50

begin
  client =
    Ai::OpenaiClient.new

  puts "Modelo:"
  puts ENV.fetch(
    "OPENAI_MODEL",
    "gpt-5.6-luna"
  )

  puts
  puts "Enviando pergunta..."

  resposta =
    client.ask(
      "Responda apenas com: Conexão com a OpenAI funcionando."
    )

  puts
  puts "Resposta:"
  puts resposta

  puts
  puts "=" * 50
  puts "OK — comunicação com a OpenAI realizada."

rescue Ai::OpenaiClient::Error => e
  puts
  puts "ERRO:"
  puts e.message

  exit 1
end