puts
puts "TESTE — CHATBOT GERAL DO PORTAL"
puts "=" * 70

chatbot =
  Ai::Chatbot.new

questions = [
  {
    domain: "ENEM",
    question:
      "Qual foi a média de Matemática de MG em 2025 na rede estadual?"
  },

  {
    domain: "ATENDIMENTO",
    question:
      "Quantos tíquetes foram fechados em setembro de 2026?"
  },

  {
    domain: "ENEM",
    question:
      "Quais foram os cinco estados com maior média de Matemática em 2025 na rede estadual?"
  },

  {
    domain: "ATENDIMENTO",
    question:
      "Como evoluiu o tempo médio de resolução entre março e setembro de 2026?"
  },

  {
    domain: "ENEM",
    question:
      "Compare a média de Redação de MG, SP e BA em 2025 na rede estadual."
  },

  {
    domain: "ATENDIMENTO",
    question:
      "Qual foi o tempo médio de primeira resposta em setembro de 2026?"
  }
]

questions.each_with_index do |test, index|
  puts
  puts "#{index + 1}. DOMÍNIO ESPERADO: #{test[:domain]}"
  puts
  puts "PERGUNTA"
  puts test[:question]

  puts
  puts "RESPOSTA"

  begin
    answer =
      chatbot.ask(
        test[:question]
      )

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
puts "7. AMBIGUIDADE — ENEM SEM DEPENDÊNCIA"
puts "-" * 70

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
puts "8. AMBIGUIDADE — ATENDIMENTO SEM ANO"
puts "-" * 70

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
puts "OK — CHATBOT GERAL DO PORTAL VALIDADO"