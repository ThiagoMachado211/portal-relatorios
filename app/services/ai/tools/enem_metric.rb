module Ai
  module Tools
    class EnemMetric
      class Error < StandardError; end

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
        @year = year.to_i
        @state_code = state_code.to_s.strip.upcase
        @administrative_dependency =
          administrative_dependency.to_s.strip

        @metric = metric.to_s
      end

      def call
        validate_metric!

        result = find_result!

        metadata =
          EnemCatalog.fetch(@metric)

        raw_value =
          result.public_send(@metric)

        {
          year: result.year,
          state_code: result.state_code,
          administrative_dependency:
            result.administrative_dependency,
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          value: serialize_value(
            raw_value,
            metadata[:format]
          )
        }
      end

      private

      def validate_metric!
        return if EnemCatalog.valid?(@metric)

        raise Error,
              "Indicador ENEM não permitido: #{@metric}"
      end

      def find_result!
        result =
          EnemStateResult.find_by(
            year: @year,
            state_code: @state_code,
            administrative_dependency:
              @administrative_dependency
          )

        return result if result

        raise Error,
              "Não foram encontrados dados ENEM para " \
              "#{@state_code}, #{@year}, " \
              "#{@administrative_dependency}."
      end

      def serialize_value(value, format)
        return nil if value.nil?

        case format
        when :integer
          value.to_i
        when :decimal
          value.to_f.round(2)
        when :percentage
          (value.to_f * 100).round(2)
        else
          value
        end
      end
    end
  end
end