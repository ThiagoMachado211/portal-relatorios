module Ai
  module Tools
    class EnemEvolution < EnemBase
      def self.call(
        state_code:,
        administrative_dependency:,
        metric:,
        start_year:,
        end_year:
      )
        new(
          state_code: state_code,
          administrative_dependency: administrative_dependency,
          metric: metric,
          start_year: start_year,
          end_year: end_year
        ).call
      end

      def initialize(
        state_code:,
        administrative_dependency:,
        metric:,
        start_year:,
        end_year:
      )
        @state_code =
          normalize_state_code(state_code)

        @administrative_dependency =
          normalize_dependency(
            administrative_dependency
          )

        @metric =
          metric.to_s

        validate_metric!(@metric)

        @start_year,
        @end_year =
          validate_year_range!(
            start_year,
            end_year
          )

        validate_geography!
      end

      def call
        metadata =
          metric_metadata(@metric)

        records =
          EnemStateResult
            .where(
              state_code: @state_code,
              administrative_dependency:
                @administrative_dependency,
              year: @start_year..@end_year
            )
            .order(:year)
            .index_by(&:year)

        years =
          (@start_year..@end_year).to_a

        results =
          years.map do |year|
            record =
              records[year]

            {
              year: year,
              value: record.nil? ? nil : serialize_value(
                record.public_send(@metric),
                metadata[:format]
              ),
              available: record.present?
            }
          end

        {
          state_code: @state_code,
          administrative_dependency:
            @administrative_dependency,
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          start_year: @start_year,
          end_year: @end_year,
          results: results
        }
      end

      private

      def validate_geography!
        exists =
          EnemStateResult.exists?(
            state_code: @state_code
          )

        return if exists

        raise Error,
              "Geografia ENEM inválida: #{@state_code}."
      end
    end
  end
end