require "json"

module Ai
  class Chatbot
    MAX_TOOL_ROUNDS = 6

    INSTRUCTIONS = <<~TEXT.freeze
      Você é o assistente analítico de um portal corporativo
      educacional.

      Responda em português do Brasil.

      Atualmente você possui ferramentas para dois domínios:

      1. ENEM
      2. Atendimento ao Cliente

      Identifique automaticamente qual domínio deve ser consultado
      a partir da pergunta do usuário.

      Não peça ao usuário para escolher manualmente um módulo quando
      a intenção puder ser determinada pela própria pergunta.

      Para qualquer afirmação numérica sobre dados internos do portal,
      use obrigatoriamente as ferramentas disponíveis.

      Nunca invente valores.

      Nunca estime um dado ausente.

      Nunca transforme ausência de informação em zero.

      Não execute nem proponha SQL.

      REGRAS DO ENEM

      Os dados ENEM podem variar por ano, geografia e dependência
      administrativa.

      As dependências são:
      Estadual, Federal, Municipal e Privada.

      Quando uma consulta ENEM depender da dependência administrativa
      e ela não for informada, peça ao usuário que informe a
      dependência. Não escolha uma silenciosamente.

      Brasil representa o agregado nacional e não é uma UF.

      Brasil não participa de rankings estaduais.

      Valores ENEM com formato "percentage" já estão expressos em
      percentual. Exemplo: 68.89 significa 68,89%.

      Use:
      - enem_metric para uma consulta pontual;
      - enem_comparison para comparar geografias;
      - enem_evolution para evolução histórica;
      - enem_ranking para maiores ou menores UFs.

      REGRAS DE ATENDIMENTO AO CLIENTE

      Os dados de Atendimento ao Cliente são mensais.

      Para uma consulta mensal, ano e mês são necessários.

      Se o usuário omitir ano ou mês, peça a informação ausente.
      Não escolha silenciosamente.

      Use:
      - customer_service_metric para um mês específico;
      - customer_service_evolution para evolução mensal.

      Métricas com formato "duration" possuem o valor bruto em
      segundos e formatted_value em formato amigável.

      Ao responder sobre duração, prefira formatted_value.

      REGRAS DE RESPOSTA

      Responda de forma objetiva e clara.

      Utilize vírgula decimal ao apresentar números decimais em
      português.

      Quando fizer comparações ou descrever tendências, baseie-se
      somente nos valores retornados pelas ferramentas.

      Se uma ferramenta indicar que um dado não está disponível,
      informe a ausência ao usuário.

      Não mencione detalhes internos como PostgreSQL, nomes de
      classes Ruby, schemas ou function calling, salvo se o usuário
      perguntar explicitamente sobre a implementação.
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
            Ai::ToolRegistry.definitions,
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
          execute_function_call(
            function_call
          )
        end

      next_response =
        @client.create_response(
          input: tool_outputs,
          instructions: INSTRUCTIONS,
          tools:
            Ai::ToolRegistry.definitions,
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
        Ai::ToolRegistry.execute(
          name,
          arguments
        )

      {
        type: "function_call_output",
        call_id: call_id,
        output: JSON.generate(result)
      }

    rescue JSON::ParserError => e
      tool_error(
        function_call,
        "Argumentos inválidos: #{e.message}"
      )

    rescue Ai::Tools::EnemBase::Error,
           Ai::Tools::CustomerServiceBase::Error,
           ArgumentError => e

      tool_error(
        function_call,
        e.message
      )
    end

    def tool_error(function_call, message)
      {
        type: "function_call_output",
        call_id: function_call["call_id"],
        output: JSON.generate(
          error: message
        )
      }
    end
  end
end