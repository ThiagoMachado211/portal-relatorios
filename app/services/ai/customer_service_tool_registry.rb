module Ai
  class CustomerServiceToolRegistry
    TOOL_NAMES = %w[
      customer_service_metric
      customer_service_evolution
    ].freeze

    def self.definitions
      [
        metric_definition,
        evolution_definition
      ]
    end

    def self.execute(name, arguments)
      args =
        arguments.transform_keys(&:to_sym)

      case name
      when "customer_service_metric"
        Ai::Tools::CustomerServiceMetric.call(
          **args.slice(
            :year,
            :month,
            :metric
          )
        )

      when "customer_service_evolution"
        Ai::Tools::CustomerServiceEvolution.call(
          **args.slice(
            :metric,
            :start_year,
            :start_month,
            :end_year,
            :end_month
          )
        )

      else
        raise Ai::Tools::CustomerServiceBase::Error,
              "Ferramenta de Atendimento ao Cliente " \
              "não permitida: #{name}"
      end
    end

    def self.metric_names
      Ai::Tools::CustomerServiceCatalog.names
    end

    class << self
      private

      def metric_property
        {
          type: "string",
          enum: metric_names,
          description:
            "Indicador exato do catálogo de Atendimento ao Cliente."
        }
      end

      def month_property
        {
          type: "integer",
          minimum: 1,
          maximum: 12,
          description:
            "Número do mês: janeiro=1, fevereiro=2, " \
            "março=3, ..., dezembro=12."
        }
      end

      def metric_definition
        {
          type: "function",
          name: "customer_service_metric",
          description:
            "Consulta um indicador de Atendimento ao Cliente " \
            "para um mês e ano específicos.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              year: {
                type: "integer"
              },
              month: month_property,
              metric: metric_property
            },
            required: [
              "year",
              "month",
              "metric"
            ],
            additionalProperties: false
          }
        }
      end

      def evolution_definition
        {
          type: "function",
          name: "customer_service_evolution",
          description:
            "Consulta a evolução mensal de um indicador de " \
            "Atendimento ao Cliente em determinado período.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              metric: metric_property,

              start_year: {
                type: "integer"
              },

              start_month: month_property,

              end_year: {
                type: "integer"
              },

              end_month: month_property
            },
            required: [
              "metric",
              "start_year",
              "start_month",
              "end_year",
              "end_month"
            ],
            additionalProperties: false
          }
        }
      end
    end
  end
end