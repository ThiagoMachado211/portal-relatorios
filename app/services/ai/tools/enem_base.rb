module Ai
  module Tools
    class EnemBase
      class Error < StandardError; end

      private

      def validate_metric!(metric)
        return if EnemCatalog.valid?(metric)

        raise Error,
              "Indicador ENEM não permitido: #{metric}"
      end

      def metric_metadata(metric)
        EnemCatalog.fetch(metric)
      end

      def normalize_state_code(value)
        normalized =
          value.to_s.strip

        if normalized.casecmp("brasil").zero?
          "Brasil"
        else
          normalized.upcase
        end
      end

      def normalize_dependency(value)
        normalized =
          value.to_s.strip

        dependency =
          available_dependencies.find do |item|
            item.casecmp(normalized).zero?
          end

        return dependency if dependency

        raise Error,
              "Dependência administrativa inválida: #{value}. " \
              "Valores disponíveis: #{available_dependencies.join(', ')}."
      end

      def validate_year!(year)
        normalized =
          year.to_i

        return normalized if available_years.include?(normalized)

        raise Error,
              "Ano ENEM inválido: #{year}. " \
              "Anos disponíveis: #{available_years.join(', ')}."
      end

      def validate_year_range!(start_year, end_year)
        first_year =
          validate_year!(start_year)

        last_year =
          validate_year!(end_year)

        if first_year > last_year
          raise Error,
                "O ano inicial não pode ser maior que o ano final."
        end

        [first_year, last_year]
      end

      def serialize_value(value, format)
        return nil if value.nil?

        case format
        when :integer
          value.to_i
        when :decimal
          value.to_f.round(2)
        when :percentage
          value.to_f.round(2)
        else
          value
        end
      end

      def available_years
        @available_years ||=
          EnemStateResult
            .distinct
            .order(:year)
            .pluck(:year)
      end

      def available_dependencies
        @available_dependencies ||=
          EnemStateResult
            .distinct
            .order(:administrative_dependency)
            .pluck(:administrative_dependency)
      end
    end
  end
end