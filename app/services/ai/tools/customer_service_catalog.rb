module Ai
  module Tools
    class CustomerServiceCatalog
      METRICS = {
        "output_count" => {
          label: "Saídas",
          format: :integer
        },

        "responses_count" => {
          label: "Respostas",
          format: :integer
        },

        "first_responses_count" => {
          label: "Primeiras respostas",
          format: :integer
        },

        "fcr_tickets_count" => {
          label: "Tíquetes FCR",
          format: :integer
        },

        "closed_tickets_count" => {
          label: "Tíquetes fechados",
          format: :integer
        },

        "reopened_tickets_count" => {
          label: "Tíquetes reabertos",
          format: :integer
        },

        "avg_first_response_seconds" => {
          label: "Tempo médio de primeira resposta",
          format: :duration
        },

        "avg_response_seconds" => {
          label: "Tempo médio de resposta",
          format: :duration
        },

        "avg_resolution_seconds" => {
          label: "Tempo médio de resolução",
          format: :duration
        },

        "ok_classifications_count" => {
          label: "Classificações Ok",
          format: :integer
        },

        "bad_classifications_count" => {
          label: "Classificações ruins",
          format: :integer
        },

        "good_classifications_count" => {
          label: "Boas classificações",
          format: :integer
        }
      }.freeze

      def self.fetch(metric)
        METRICS[metric.to_s]
      end

      def self.valid?(metric)
        METRICS.key?(metric.to_s)
      end

      def self.names
        METRICS.keys
      end
    end
  end
end