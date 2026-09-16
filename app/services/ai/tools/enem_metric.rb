module Ai
  module Tools
    class EnemMetric < EnemBase
      def self.call(
        year:,
        state_code:,
        administrative_dependency:,
        metric:
      )
        new(
          year: year,
          state_code: state_code,
          administrative_dependency: administrative_dependency,
          metric: metric
        ).call
      end

      def initialize(
        year:,
        state_code:,
        administrative_dependency:,
        metric:
      )
        @year =
          validate_year!(year)

        @state_code =
          normalize_state_code(state_code)

        @administrative_dependency =
          normalize_dependency(
            administrative_dependency
          )

        @metric =
          metric.to_s

        validate_metric!(@metric)
      end

      def call
        result =
          EnemStateResult.find_by(
            year: @year,
            state_code: @state_code,
            administrative_dependency:
              @administrative_dependency
          )

        unless result
          raise Error,
                "Não foram encontrados dados ENEM para " \
                "#{@state_code}, #{@year}, " \
                "#{@administrative_dependency}."
        end

        metadata =
          metric_metadata(@metric)

        {
          year: result.year,
          state_code: result.state_code,
          administrative_dependency:
            result.administrative_dependency,
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          value: serialize_value(
            result.public_send(@metric),
            metadata[:format]
          )
        }
      end
    end
  end
end