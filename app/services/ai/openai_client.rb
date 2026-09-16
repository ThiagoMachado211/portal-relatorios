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
      response = request(
        model: @model,
        input: message
      )

      extract_text(response)
    end

    private

    def request(payload)
      uri = URI(API_URL)

      http = Net::HTTP.new(
        uri.host,
        uri.port
      )

      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)

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
  end
end