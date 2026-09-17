module Ai
  class ConversationContext
    MAX_MESSAGES = 12

    def self.build(question:, history: [])
      new(
        question: question,
        history: history
      ).build
    end

    def initialize(question:, history:)
      @question = question.to_s.strip
      @history = Array(history)
    end

    def build
      return @question if normalized_history.empty?

      <<~TEXT.strip
        Abaixo está o histórico recente desta mesma conversa.

        Use esse histórico somente para interpretar referências,
        continuações e informações omitidas na pergunta atual.

        Não trate respostas anteriores do assistente como fonte
        oficial dos dados. Para responder perguntas analíticas,
        continue utilizando exclusivamente as ferramentas
        analíticas disponíveis no portal.

        HISTÓRICO DA CONVERSA:

        #{formatted_history}

        PERGUNTA ATUAL:

        #{@question}
      TEXT
    end

    private

    def normalized_history
      @normalized_history ||=
        @history
          .last(MAX_MESSAGES)
          .filter_map do |message|
            role =
              message["role"] ||
              message[:role]

            content =
              message["content"] ||
              message[:content]

            next unless %w[user assistant].include?(
              role.to_s
            )

            content = content.to_s.strip

            next if content.blank?

            {
              role: role.to_s,
              content: content
            }
          end
    end

    def formatted_history
      normalized_history
        .map do |message|
          speaker =
            if message[:role] == "user"
              "USUÁRIO"
            else
              "ASSISTENTE"
            end

          "#{speaker}: #{message[:content]}"
        end
        .join("\n\n")
    end
  end
end