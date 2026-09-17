class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  MAX_HISTORY_MESSAGES = 12

  def create
    question =
      params[:question].to_s.strip

    if question.blank?
      return render json: {
        error: "Digite uma pergunta."
      }, status: :unprocessable_entity
    end

    answer =
      Ai::Chatbot.new(
        user: current_user
      ).ask(
        question,
        history: chatbot_history
      )

    append_to_history(
      role: "user",
      content: question
    )

    append_to_history(
      role: "assistant",
      content: answer
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
      chatbot_session_key
    )

    render json: {
      ok: true
    }
  end

  private

  def chatbot_history
    Array(
      session[chatbot_session_key]
    )
  end

  def append_to_history(role:, content:)
    history =
      chatbot_history.dup

    history << {
      "role" => role.to_s,
      "content" => content.to_s
    }

    session[chatbot_session_key] =
      history.last(
        MAX_HISTORY_MESSAGES
      )
  end

  def chatbot_session_key
    "chatbot_history_user_#{current_user.id}"
  end
end