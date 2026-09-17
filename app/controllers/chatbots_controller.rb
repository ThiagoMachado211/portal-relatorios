class ChatbotsController < ApplicationController
  before_action :authenticate_user!

  def create
    question =
      params[:question].to_s.strip

    if question.blank?
      return render json: {
        error: "Digite uma pergunta."
      }, status: :unprocessable_entity
    end

    answer =
      Ai::Chatbot.new.ask(question)

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

    render json: {
      error:
        "Ocorreu um erro ao processar sua pergunta."
    }, status: :internal_server_error
  end
end