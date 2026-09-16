puts
puts "TESTE — CHATBOT ANALÍTICO ENEM"
puts "=" * 70

chatbot =
  Ai::EnemChatbot.new

questions = [
  "Qual foi a média de Matemática de MG em 2025 na rede estadual?",

  "Compare as médias de Redação de MG, SP e BA em 2025 na rede estadual.",

  "Como evoluiu a média de Redação de Minas Gerais entre 2016 e 2025 na rede estadual?",

  "Quais foram os cinco estados com maior média de Matemática em 2025 na rede estadual?"
]

questions.each_with_index do |question, index|
  puts
  puts "#{index + 1}. PERGUNTA"
  puts question

  puts
  puts "RESPOSTA"

  begin
    answer =
      chatbot.ask(question)

    puts answer

  rescue StandardError => e
    puts "ERRO: #{e.class}"
    puts e.message
    exit 1
  end

  puts
  puts "-" * 70
end

puts
puts "5. TESTE — DEPENDÊNCIA NÃO INFORMADA"

begin
  answer =
    chatbot.ask(
      "Qual foi a média de Matemática de MG em 2025?"
    )

  puts answer

rescue StandardError => e
  puts "ERRO: #{e.class}"
  puts e.message
  exit 1
end

puts
puts "=" * 70
puts "OK — TESTE DO CHATBOT ENEM CONCLUÍDO"