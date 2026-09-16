module Ai
  module Tools
    class EnemRanking < EnemBase
      DIRECTIONS = %w[highest lowest].freeze

      DEFAULT_LIMIT = 5
      MAX_LIMIT = 27

      def self.call(
        year:,
        administrative_dependency:,
        metric:,
        direction: "highest",
        limit: DEFAULT_LIMIT
      )
        new(
          year: year,
          administrative_dependency: administrative_dependency,
          metric: metric,
          direction: direction,
          limit: limit
        ).call
      end

      def initialize(
        year:,
        administrative_dependency:,
        metric:,
        direction:,
        limit:
      )
        @year =
          validate_year!(year)

        @administrative_dependency =
          normalize_dependency(
            administrative_dependency
          )

        @metric =
          metric.to_s

        validate_metric!(@metric)

        @direction =
          direction.to_s.downcase.strip

        @limit =
          limit.to_i

        validate_direction!
        validate_limit!
      end

      def call
        metadata =
          metric_metadata(@metric)

        records =
          EnemStateResult
            .where(
              year: @year,
              administrative_dependency:
                @administrative_dependency
            )
            .where.not(
              state_code: "Brasil"
            )
            .where.not(
              @metric => nil
            )

        values =
          records.map do |record|
            {
              state_code: record.state_code,
              value: serialize_value(
                record.public_send(@metric),
                metadata[:format]
              )
            }
          end

        sorted =
          values.sort_by do |item|
            item[:value]
          end

        sorted.reverse! if @direction == "highest"

        selected =
          sorted.first(@limit)

        ranked =
          selected.each_with_index.map do |item, index|
            {
              position: index + 1,
              state_code: item[:state_code],
              value: item[:value]
            }
          end

        {
          year: @year,
          administrative_dependency:
            @administrative_dependency,
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          direction: @direction,
          requested_limit: @limit,
          total_states_available: values.length,
          results: ranked
        }
      end

      private

      def validate_direction!
        return if DIRECTIONS.include?(@direction)

        raise Error,
              "Direção de ranking inválida: #{@direction}. " \
              "Use highest ou lowest."
      end

      def validate_limit!
        if @limit < 1 || @limit > MAX_LIMIT
          raise Error,
                "O ranking deve solicitar entre 1 e " \
                "#{MAX_LIMIT} estados."
        end
      end
    end
  end
end