puts
puts "TESTE — HISTÓRICO DO CHATBOT NO BANCO"
puts "=" * 70

user =
  User.first

raise "Nenhum usuário encontrado." unless user

conversation =
  user.chat_conversations.create!

puts
puts "Conversa criada:"
puts "ID: #{conversation.id}"
puts "Usuário: #{user.email}"

conversation.chat_messages.create!(
  role: :user,
  content: "Pergunta de teste"
)

conversation.chat_messages.create!(
  role: :assistant,
  content: "Resposta de teste"
)

puts
puts "Mensagens:"
puts "-" * 70

conversation
  .chat_messages
  .order(:created_at)
  .each do |message|

    puts(
      "#{message.role}: " \
      "#{message.content}"
    )
  end

count =
  conversation.chat_messages.count

raise "Quantidade incorreta." unless count == 2

unless conversation.user == user
  raise "Associação com usuário incorreta."
end

conversation.destroy!

if ChatMessage.where(
  chat_conversation_id: conversation.id
).exists?
  raise "Dependent destroy não funcionou."
end

puts
puts "=" * 70
puts "OK — HISTÓRICO PERSISTENTE VALIDADO."
puts "=" * 70