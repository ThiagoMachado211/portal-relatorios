class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  CONTEXT_MESSAGE_LIMIT = 12

  def create
    question =
      params[:question].to_s.strip

    if question.blank?
      return render json: {
        error: "Digite uma pergunta."
      }, status: :unprocessable_entity
    end

    conversation =
      current_chat_conversation

    history =
      conversation_history(
        conversation
      )

    answer =
      Ai::Chatbot.new(
        user: current_user
      ).ask(
        question,
        history: history
      )

    save_exchange!(
      conversation: conversation,
      question: question,
      answer: answer
    )

    render json: {
      answer: answer
    }

  rescue Ai::OpenaiClient::Error => e
    Rails.logger.error(
      "[Chatbot] OpenAI error: #{e.message}"
    )

    render json: {
      error:
        "Não foi possível consultar o assistente agora. " \
        "Tente novamente em instantes."
    }, status: :service_unavailable

  rescue StandardError => e
    Rails.logger.error(
      "[Chatbot] #{e.class}: #{e.message}"
    )

    Rails.logger.error(
      e.backtrace.first(10).join("\n")
    ) if e.backtrace

    render json: {
      error:
        "Ocorreu um erro ao processar sua pergunta."
    }, status: :internal_server_error
  end

  def destroy
    session.delete(
      chatbot_conversation_session_key
    )

    render json: {
      ok: true
    }
  end

  private

  def current_chat_conversation
    conversation =
      conversation_from_session

    return conversation if conversation

    create_chat_conversation!
  end

  def conversation_from_session
    conversation_id =
      session[
        chatbot_conversation_session_key
      ]

    return nil if conversation_id.blank?

    current_user
      .chat_conversations
      .find_by(
        id: conversation_id
      )
  end

  def create_chat_conversation!
    conversation =
      current_user
        .chat_conversations
        .create!

    session[
      chatbot_conversation_session_key
    ] = conversation.id

    conversation
  end

  def conversation_history(conversation)
    messages =
      conversation
        .chat_messages
        .order(created_at: :desc)
        .limit(CONTEXT_MESSAGE_LIMIT)
        .to_a
        .reverse

    messages.map do |message|
      {
        "role" => message.role,
        "content" => message.content
      }
    end
  end

  def save_exchange!(
    conversation:,
    question:,
    answer:
  )
    ChatMessage.transaction do
      conversation
        .chat_messages
        .create!(
          role: :user,
          content: question
        )

      conversation
        .chat_messages
        .create!(
          role: :assistant,
          content: answer.to_s
        )
    end
  end

  def chatbot_conversation_session_key
    "chatbot_conversation_user_#{current_user.id}"
  end
end