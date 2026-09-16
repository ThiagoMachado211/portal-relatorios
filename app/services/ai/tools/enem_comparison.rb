module Ai
  module Tools
    class EnemComparison < EnemBase
      MAX_GEOGRAPHIES = 28

      def self.call(
        year:,
        state_codes:,
        administrative_dependency:,
        metric:
      )
        new(
          year: year,
          state_codes: state_codes,
          administrative_dependency: administrative_dependency,
          metric: metric
        ).call
      end

      def initialize(
        year:,
        state_codes:,
        administrative_dependency:,
        metric:
      )
        @year =
          validate_year!(year)

        @state_codes =
          Array(state_codes)
            .map { |code| normalize_state_code(code) }
            .uniq

        @administrative_dependency =
          normalize_dependency(
            administrative_dependency
          )

        @metric =
          metric.to_s

        validate_metric!(@metric)
        validate_geographies!
      end

      def call
        metadata =
          metric_metadata(@metric)

        records =
          EnemStateResult
            .where(
              year: @year,
              state_code: @state_codes,
              administrative_dependency:
                @administrative_dependency
            )
            .index_by(&:state_code)

        results =
          @state_codes.map do |state_code|
            record =
              records[state_code]

            {
              state_code: state_code,
              value: record.nil? ? nil : serialize_value(
                record.public_send(@metric),
                metadata[:format]
              ),
              available: record.present?
            }
          end

        {
          year: @year,
          administrative_dependency:
            @administrative_dependency,
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          results: results
        }
      end

      private

      def validate_geographies!
        if @state_codes.empty?
          raise Error,
                "Informe ao menos uma geografia."
        end

        if @state_codes.length > MAX_GEOGRAPHIES
          raise Error,
                "O limite é de #{MAX_GEOGRAPHIES} geografias por comparação."
        end

        valid_codes =
          EnemStateResult
            .where(state_code: @state_codes)
            .distinct
            .pluck(:state_code)

        invalid_codes =
          @state_codes - valid_codes

        return if invalid_codes.empty?

        raise Error,
              "Geografia ENEM inválida: " \
              "#{invalid_codes.join(', ')}."
      end
    end
  end
end