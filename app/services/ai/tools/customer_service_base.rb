module Ai
  module Tools
    class CustomerServiceBase
      class Error < StandardError; end

      MONTH_NAMES = {
        1 => "Janeiro",
        2 => "Fevereiro",
        3 => "Março",
        4 => "Abril",
        5 => "Maio",
        6 => "Junho",
        7 => "Julho",
        8 => "Agosto",
        9 => "Setembro",
        10 => "Outubro",
        11 => "Novembro",
        12 => "Dezembro"
      }.freeze

      private

      def validate_metric!(metric)
        return if CustomerServiceCatalog.valid?(metric)

        raise Error,
              "Indicador de Atendimento ao Cliente não permitido: #{metric}"
      end

      def metric_metadata(metric)
        CustomerServiceCatalog.fetch(metric)
      end

      def normalize_year(value)
        year = Integer(value)

        return year if available_years.include?(year)

        raise Error,
              "Ano inválido: #{value}. " \
              "Anos disponíveis: #{available_years.join(', ')}."

      rescue ArgumentError, TypeError
        raise Error,
              "Ano inválido: #{value}."
      end

      def normalize_month(value)
        month = Integer(value)

        return month if MONTH_NAMES.key?(month)

        raise Error,
              "Mês inválido: #{value}. Use um valor entre 1 e 12."

      rescue ArgumentError, TypeError
        raise Error,
              "Mês inválido: #{value}. Use um valor entre 1 e 12."
      end

      def month_name(month)
        MONTH_NAMES.fetch(month)
      end

      def serialize_value(value, format)
        return {
          value: nil,
          formatted_value: nil
        } if value.nil?

        case format
        when :integer
          {
            value: value.to_i,
            formatted_value: value.to_i.to_s
          }

        when :duration
          seconds = value.to_i

          {
            value: seconds,
            formatted_value: format_duration(seconds)
          }

        else
          {
            value: value,
            formatted_value: value.to_s
          }
        end
      end

      def format_duration(total_seconds)
        seconds = total_seconds.to_i

        hours =
          seconds / 3600

        minutes =
          (seconds % 3600) / 60

        remaining_seconds =
          seconds % 60

        parts = []

        parts << "#{hours}h" if hours.positive?
        parts << "#{minutes}min" if minutes.positive?
        parts << "#{remaining_seconds}s" if remaining_seconds.positive?

        parts << "0s" if parts.empty?

        parts.join(" ")
      end

      def available_years
        @available_years ||=
          CustomerServiceMonthlyResult
            .distinct
            .order(:year)
            .pluck(:year)
      end
    end
  end
end