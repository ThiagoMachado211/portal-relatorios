puts
puts "TESTE — CHATBOT DE ATENDIMENTO AO CLIENTE"
puts "=" * 70

chatbot =
  Ai::CustomerServiceChatbot.new

questions = [
  "Quantos tíquetes foram fechados em setembro de 2026?",

  "Qual foi o tempo médio de primeira resposta em setembro de 2026?",

  "Qual foi o tempo médio de resolução em setembro de 2026?",

  "Como evoluiu a quantidade de tíquetes FCR entre março e setembro de 2026?",

  "Como evoluiu o tempo médio de resolução entre março e setembro de 2026?"
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
puts "6. TESTE — ANO NÃO INFORMADO"

begin
  answer =
    chatbot.ask(
      "Quantos tíquetes foram fechados em setembro?"
    )

  puts answer

rescue StandardError => e
  puts "ERRO: #{e.class}"
  puts e.message
  exit 1
end

puts
puts "=" * 70
puts "OK — TESTE DO CHATBOT DE ATENDIMENTO CONCLUÍDO"