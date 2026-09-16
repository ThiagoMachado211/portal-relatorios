require "net/http"
require "json"
require "uri"

module Ai
  class OpenaiClient
    API_URL = "https://api.openai.com/v1/responses"

    class Error < StandardError; end

    def initialize(
      api_key: ENV["OPENAI_API_KEY"],
      model: ENV.fetch("OPENAI_MODEL", "gpt-5.6-luna")
    )
      @api_key = api_key
      @model = model

      if @api_key.blank?
        raise Error, "OPENAI_API_KEY não está configurada."
      end
    end

    def ask(message)
      response = create_response(
        input: message
      )

      extract_text(response)
    end

    def create_response(
      input:,
      instructions: nil,
      tools: nil,
      previous_response_id: nil,
      tool_choice: nil
    )
      payload = {
        model: @model,
        input: input
      }

      payload[:instructions] =
        instructions if instructions.present?

      payload[:tools] =
        tools if tools.present?

      payload[:previous_response_id] =
        previous_response_id if previous_response_id.present?

      payload[:tool_choice] =
        tool_choice if tool_choice.present?

      request(payload)
    end

    def extract_text(response)
      texts =
        Array(response["output"])
          .select do |item|
            item["type"] == "message"
          end
          .flat_map do |item|
            Array(item["content"])
          end
          .select do |content|
            content["type"] == "output_text"
          end
          .map do |content|
            content["text"]
          end

      text =
        texts.join("\n").strip

      if text.blank?
        raise Error,
              "A OpenAI respondeu, mas não retornou texto."
      end

      text
    end

    private

    def request(payload)
      uri =
        URI(API_URL)

      http =
        Net::HTTP.new(
          uri.host,
          uri.port
        )

      http.use_ssl = true
      http.open_timeout = 15
      http.read_timeout = 90

      request =
        Net::HTTP::Post.new(uri)

      request["Authorization"] =
        "Bearer #{@api_key}"

      request["Content-Type"] =
        "application/json"

      request.body =
        JSON.generate(payload)

      response =
        http.request(request)

      body =
        parse_response(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message =
          body.dig("error", "message") ||
          "Erro desconhecido da OpenAI."

        raise Error,
              "OpenAI API retornou HTTP #{response.code}: #{message}"
      end

      body

    rescue JSON::ParserError => e
      raise Error,
            "Resposta inválida da OpenAI: #{e.message}"

    rescue SocketError,
           Errno::ECONNREFUSED,
           Net::OpenTimeout,
           Net::ReadTimeout => e

      raise Error,
            "Falha de conexão com a OpenAI: #{e.message}"
    end

    def parse_response(body)
      JSON.parse(body)
    end
  end
end