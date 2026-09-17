require "json"

module Ai
  class CustomerServiceChatbot
    MAX_TOOL_ROUNDS = 4

    INSTRUCTIONS = <<~TEXT.freeze
      Você é o assistente analítico do módulo de Atendimento ao
      Cliente de um portal corporativo.

      Responda em português do Brasil.

      Para qualquer afirmação numérica sobre os dados de Atendimento
      ao Cliente deste portal, use obrigatoriamente uma das
      ferramentas fornecidas.

      Nunca invente valores, nunca estime dados ausentes e nunca
      transforme ausência de informação em zero.

      Os dados estão organizados mensalmente.

      Se uma consulta mensal precisar de ano e mês e o usuário não
      fornecer uma dessas informações, peça a informação ausente.
      Não escolha silenciosamente um ano ou mês.

      Para perguntas sobre um único mês, use
      customer_service_metric.

      Para perguntas sobre evolução ou comportamento ao longo de
      vários meses, use customer_service_evolution.

      Métricas cujo formato seja "duration" possuem:
      - value: duração original em segundos;
      - formatted_value: representação amigável da duração.

      Ao responder ao usuário sobre duração, prefira
      formatted_value.

      Valores com available=false representam ausência de dado,
      e nunca devem ser interpretados como zero.

      Seja objetivo e destaque tendências somente quando elas forem
      sustentadas pelos valores retornados.

      Não mencione PostgreSQL, classes Ruby, schemas de ferramentas
      ou function calling, salvo se o usuário perguntar
      explicitamente sobre a implementação.
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
            Ai::CustomerServiceToolRegistry.definitions,
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
            Ai::CustomerServiceToolRegistry.definitions,
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
        Ai::CustomerServiceToolRegistry.execute(
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

    rescue Ai::Tools::CustomerServiceBase::Error,
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