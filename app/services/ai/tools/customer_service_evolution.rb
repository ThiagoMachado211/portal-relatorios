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
            .order(:year, :month)
            .select do |record|
              inside_period?(
                record.year,
                record.month
              )
            end

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
          period_position(
            @start_year,
            @start_month
          )

        end_position =
          period_position(
            @end_year,
            @end_month
          )

        return if start_position <= end_position

        raise Error,
              "O período inicial não pode ser posterior ao período final."
      end

      def inside_period?(year, month)
        position =
          period_position(
            year,
            month
          )

        position >= start_position &&
          position <= end_position
      end

      def start_position
        @start_position ||=
          period_position(
            @start_year,
            @start_month
          )
      end

      def end_position
        @end_position ||=
          period_position(
            @end_year,
            @end_month
          )
      end

      def period_position(year, month)
        (year * 12) + month
      end
    end
  end
end