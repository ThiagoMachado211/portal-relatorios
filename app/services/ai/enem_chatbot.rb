require "json"

module Ai
  class EnemChatbot
    MAX_TOOL_ROUNDS = 4

    INSTRUCTIONS = <<~TEXT.freeze
      Você é o assistente analítico do módulo ENEM de um portal
      educacional brasileiro.

      Responda em português do Brasil.

      Para qualquer afirmação numérica sobre os dados ENEM deste
      portal, use obrigatoriamente uma das ferramentas fornecidas.

      Nunca invente valores e nunca estime dados ausentes.

      As dependências administrativas disponíveis são:
      Estadual, Federal, Municipal e Privada.

      Quando o usuário não informar a dependência administrativa,
      não escolha uma silenciosamente. Explique que é necessário
      informar a dependência.

      Brasil representa o agregado nacional e não deve ser tratado
      como uma UF.

      Rankings estaduais devem usar enem_ranking. O agregado Brasil
      não participa desses rankings.

      Valores cujo formato retornado seja "percentage" já estão
      expressos em percentual. Por exemplo, 68.89 significa 68,89%.

      Valores com available=false representam ausência de dado,
      e nunca devem ser interpretados como zero.

      Para perguntas pontuais, prefira enem_metric.
      Para comparação entre geografias, use enem_comparison.
      Para séries históricas, use enem_evolution.
      Para maiores ou menores estados, use enem_ranking.

      Seja objetivo. Apresente os números com vírgula decimal
      quando escrever em português.

      Não mencione detalhes internos como PostgreSQL, nomes de
      classes Ruby, schemas de ferramentas ou function calling,
      salvo se o usuário perguntar explicitamente sobre a
      implementação.
    TEXT

    def initialize(
      client: Ai::OpenaiClient.new
    )
      @client = client
    end

    def ask(question)
      question =
        question.to_s.strip

      if question.blank?
        raise ArgumentError,
              "A pergunta não pode estar vazia."
      end

      response =
        @client.create_response(
          input: question,
          instructions: INSTRUCTIONS,
          tools:
            Ai::EnemToolRegistry.definitions,
          tool_choice: "auto"
        )

      process_response(
        response,
        round: 1
      )
    end

    private

    def process_response(response, round:)
      function_calls =
        Array(response["output"]).select do |item|
          item["type"] == "function_call"
        end

      if function_calls.empty?
        return @client.extract_text(response)
      end

      if round > MAX_TOOL_ROUNDS
        raise Ai::OpenaiClient::Error,
              "O chatbot excedeu o limite de ciclos de ferramentas."
      end

      tool_outputs =
        function_calls.map do |function_call|
          execute_function_call(function_call)
        end

      next_response =
        @client.create_response(
          input: tool_outputs,
          instructions: INSTRUCTIONS,
          tools:
            Ai::EnemToolRegistry.definitions,
          previous_response_id:
            response.fetch("id"),
          tool_choice: "auto"
        )

      process_response(
        next_response,
        round: round + 1
      )
    end

    def execute_function_call(function_call)
      name =
        function_call.fetch("name")

      call_id =
        function_call.fetch("call_id")

      arguments =
        JSON.parse(
          function_call.fetch("arguments")
        )

      result =
        Ai::EnemToolRegistry.execute(
          name,
          arguments
        )

      {
        type: "function_call_output",
        call_id: call_id,
        output: JSON.generate(result)
      }

    rescue JSON::ParserError => e
      {
        type: "function_call_output",
        call_id: function_call["call_id"],
        output: JSON.generate(
          error:
            "Argumentos inválidos: #{e.message}"
        )
      }

    rescue Ai::Tools::EnemBase::Error,
           ArgumentError => e

      {
        type: "function_call_output",
        call_id: function_call["call_id"],
        output: JSON.generate(
          error: e.message
        )
      }
    end
  end
end