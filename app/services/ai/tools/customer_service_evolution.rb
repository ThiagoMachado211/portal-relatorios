module Ai
  module Tools
    class CustomerServiceEvolution < CustomerServiceBase
      def self.call(
        metric:,
        start_year:,
        start_month:,
        end_year:,
        end_month:
      )
        new(
          metric: metric,
          start_year: start_year,
          start_month: start_month,
          end_year: end_year,
          end_month: end_month
        ).call
      end

      def initialize(
        metric:,
        start_year:,
        start_month:,
        end_year:,
        end_month:
      )
        @metric =
          metric.to_s

        validate_metric!(@metric)

        @start_year =
          normalize_year(start_year)

        @start_month =
          normalize_month(start_month)

        @end_year =
          normalize_year(end_year)

        @end_month =
          normalize_month(end_month)

        validate_period!
      end

      def call
        metadata =
          metric_metadata(@metric)

        records =
          CustomerServiceMonthlyResult
            .where(
              period_condition
            )
            .order(:year, :month)

        if records.empty?
          raise Error,
                "Não foram encontrados dados de Atendimento ao Cliente " \
                "para o período informado."
        end

        results =
          records.map do |record|
            serialized =
              serialize_value(
                record.public_send(@metric),
                metadata[:format]
              )

            {
              year: record.year,
              month: record.month,
              month_name:
                month_name(record.month),
              value:
                serialized[:value],
              formatted_value:
                serialized[:formatted_value],
              available:
                !serialized[:value].nil?
            }
          end

        {
          metric: @metric,
          label: metadata[:label],
          format: metadata[:format],

          start_year: @start_year,
          start_month: @start_month,
          end_year: @end_year,
          end_month: @end_month,

          results: results
        }
      end

      private

      def validate_period!
        start_position =
          (@start_year * 12) + @start_month

        end_position =
          (@end_year * 12) + @end_month

        return if start_position <= end_position

        raise Error,
              "O período inicial não pode ser posterior ao período final."
      end

      def period_condition
        start_date =
          Date.new(
            @start_year,
            @start_month,
            1
          )

        end_date =
          Date.new(
            @end_year,
            @end_month,
            1
          )

        start_key =
          (start_date.year * 100) +
          start_date.month

        end_key =
          (end_date.year * 100) +
          end_date.month

        CustomerServiceMonthlyResult
          .arel_table[:year]
          .multiply(100)
          .plus(
            CustomerServiceMonthlyResult
              .arel_table[:month]
          )
          .between(start_key..end_key)
      end
    end
  end
end