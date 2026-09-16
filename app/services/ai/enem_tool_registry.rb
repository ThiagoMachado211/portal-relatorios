module Ai
  class EnemToolRegistry
    TOOL_NAMES = %w[
      enem_metric
      enem_comparison
      enem_evolution
      enem_ranking
    ].freeze

    def self.definitions
      [
        metric_definition,
        comparison_definition,
        evolution_definition,
        ranking_definition
      ]
    end

    def self.execute(name, arguments)
      args =
        arguments.transform_keys(&:to_sym)

      case name
      when "enem_metric"
        Ai::Tools::EnemMetric.call(
          **args.slice(
            :year,
            :state_code,
            :administrative_dependency,
            :metric
          )
        )

      when "enem_comparison"
        Ai::Tools::EnemComparison.call(
          **args.slice(
            :year,
            :state_codes,
            :administrative_dependency,
            :metric
          )
        )

      when "enem_evolution"
        Ai::Tools::EnemEvolution.call(
          **args.slice(
            :state_code,
            :administrative_dependency,
            :metric,
            :start_year,
            :end_year
          )
        )

      when "enem_ranking"
        Ai::Tools::EnemRanking.call(
          **args.slice(
            :year,
            :administrative_dependency,
            :metric,
            :direction,
            :limit
          )
        )

      else
        raise Ai::Tools::EnemBase::Error,
              "Ferramenta ENEM não permitida: #{name}"
      end
    end

    def self.metric_names
      Ai::Tools::EnemCatalog.names
    end

    class << self
      private

      def common_metric_property
        {
          type: "string",
          enum: metric_names,
          description:
            "Indicador exato do catálogo ENEM."
        }
      end

      def dependency_property
        {
          type: "string",
          enum: [
            "Estadual",
            "Federal",
            "Municipal",
            "Privada"
          ],
          description:
            "Dependência administrativa."
        }
      end

      def state_property
        {
          type: "string",
          description:
            "Sigla da UF, como MG, SP ou BA. " \
            "Use Brasil para o agregado nacional."
        }
      end

      def metric_definition
        {
          type: "function",
          name: "enem_metric",
          description:
            "Consulta um único indicador ENEM para " \
            "um ano, geografia e dependência administrativa.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              year: {
                type: "integer"
              },
              state_code: state_property,
              administrative_dependency:
                dependency_property,
              metric:
                common_metric_property
            },
            required: [
              "year",
              "state_code",
              "administrative_dependency",
              "metric"
            ],
            additionalProperties: false
          }
        }
      end

      def comparison_definition
        {
          type: "function",
          name: "enem_comparison",
          description:
            "Compara o mesmo indicador ENEM entre " \
            "duas ou mais geografias no mesmo ano.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              year: {
                type: "integer"
              },
              state_codes: {
                type: "array",
                items: state_property,
                minItems: 1,
                maxItems: 28
              },
              administrative_dependency:
                dependency_property,
              metric:
                common_metric_property
            },
            required: [
              "year",
              "state_codes",
              "administrative_dependency",
              "metric"
            ],
            additionalProperties: false
          }
        }
      end

      def evolution_definition
        {
          type: "function",
          name: "enem_evolution",
          description:
            "Consulta a evolução histórica de um " \
            "indicador ENEM para uma geografia.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              state_code:
                state_property,
              administrative_dependency:
                dependency_property,
              metric:
                common_metric_property,
              start_year: {
                type: "integer"
              },
              end_year: {
                type: "integer"
              }
            },
            required: [
              "state_code",
              "administrative_dependency",
              "metric",
              "start_year",
              "end_year"
            ],
            additionalProperties: false
          }
        }
      end

      def ranking_definition
        {
          type: "function",
          name: "enem_ranking",
          description:
            "Cria ranking das UFs para um indicador " \
            "ENEM. Brasil não participa do ranking.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              year: {
                type: "integer"
              },
              administrative_dependency:
                dependency_property,
              metric:
                common_metric_property,
              direction: {
                type: "string",
                enum: [
                  "highest",
                  "lowest"
                ]
              },
              limit: {
                type: "integer",
                minimum: 1,
                maximum: 27
              }
            },
            required: [
              "year",
              "administrative_dependency",
              "metric",
              "direction",
              "limit"
            ],
            additionalProperties: false
          }
        }
      end
    end
  end
end