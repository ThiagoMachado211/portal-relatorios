module Ai
  module Tools
    class CustomerServiceMetric < CustomerServiceBase
      def self.call(
        year:,
        month:,
        metric:
      )
        new(
          year: year,
          month: month,
          metric: metric
        ).call
      end

      def initialize(
        year:,
        month:,
        metric:
      )
        @year =
          normalize_year(year)

        @month =
          normalize_month(month)

        @metric =
          metric.to_s

        validate_metric!(@metric)
      end

      def call
        result =
          CustomerServiceMonthlyResult.find_by(
            year: @year,
            month: @month
          )

        unless result
          raise Error,
                "Não foram encontrados dados de Atendimento ao Cliente " \
                "para #{month_name(@month)} de #{@year}."
        end

        metadata =
          metric_metadata(@metric)

        serialized =
          serialize_value(
            result.public_send(@metric),
            metadata[:format]
          )

        {
          year: @year,
          month: @month,
          month_name: month_name(@month),
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],
          value: serialized[:value],
          formatted_value:
            serialized[:formatted_value]
        }
      end
    end
  end
end