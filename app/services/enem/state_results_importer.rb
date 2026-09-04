require "csv"
require "bigdecimal"

module Enem
  class StateResultsImporter
    DEFAULT_PATH = Rails.root.join(
      "db",
      "import_data",
      "enem",
      "Base_ENEM_2016_a_2025.csv"
    )

    COLUMN_MAP = {
      "ANO" => :year,
      "SG_UF_ESC" => :state_code,
      "DEPENDENCIA" => :administrative_dependency,

      "N_INSCRITOS" => :registered_count,
      "N_PARTICIPANTES_D1" => :participants_day1_count,
      "N_PARTICIPANTES_D2" => :participants_day2_count,
      "N_PARTICIPANTES_D1D2" => :participants_both_days_count,

      "PERC_PARTIC_D1" => :participation_day1_pct,
      "PERC_PARTIC_D2" => :participation_day2_pct,
      "PERC_PARTIC_D1D2" => :participation_both_days_pct,

      "MEDIA_CH" => :human_sciences_average,
      "MEDIA_LC" => :languages_average,
      "MEDIA_CN" => :natural_sciences_average,
      "MEDIA_MT" => :mathematics_average,
      "MEDIA_REDACAO" => :essay_average,
      "MEDIA_GERAL" => :general_average,

      "MEDIA_COMP1" => :essay_competency_1_average,
      "MEDIA_COMP2" => :essay_competency_2_average,
      "MEDIA_COMP3" => :essay_competency_3_average,
      "MEDIA_COMP4" => :essay_competency_4_average,
      "MEDIA_COMP5" => :essay_competency_5_average,

      "N_REDACOES" => :essays_count,

      "N_RED_SEM_PROBLEMAS" => :essays_ok_count,
      "N_RED_ANULADA" => :essays_annulled_count,
      "N_RED_COPIA_TEXTO_MOTIVADOR" => :essays_motivating_text_copy_count,
      "N_RED_EM_BRANCO" => :essays_blank_count,
      "N_RED_FERE_DH" => :essays_human_rights_violation_count,
      "N_RED_FUGA_TEMA" => :essays_off_topic_count,
      "N_RED_TIPO_TEXTUAL" => :essays_wrong_text_type_count,
      "N_RED_TEXTO_INSUFICIENTE" => :essays_insufficient_text_count,
      "N_RED_PARTE_DESCONECTADA" => :essays_disconnected_part_count,

      "PERC_RED_SEM_PROBLEMAS" => :essays_ok_pct,
      "PERC_RED_ANULADA" => :essays_annulled_pct,
      "PERC_RED_COPIA_TEXTO_MOTIVADOR" => :essays_motivating_text_copy_pct,
      "PERC_RED_EM_BRANCO" => :essays_blank_pct,
      "PERC_RED_FERE_DH" => :essays_human_rights_violation_pct,
      "PERC_RED_FUGA_TEMA" => :essays_off_topic_pct,
      "PERC_RED_TIPO_TEXTUAL" => :essays_wrong_text_type_pct,
      "PERC_RED_TEXTO_INSUFICIENTE" => :essays_insufficient_text_pct,
      "PERC_RED_PARTE_DESCONECTADA" => :essays_disconnected_part_pct
    }.freeze

    INTEGER_FIELDS = %i[
      year
      registered_count
      participants_day1_count
      participants_day2_count
      participants_both_days_count
      essays_count
      essays_ok_count
      essays_annulled_count
      essays_motivating_text_copy_count
      essays_blank_count
      essays_human_rights_violation_count
      essays_off_topic_count
      essays_wrong_text_type_count
      essays_insufficient_text_count
      essays_disconnected_part_count
    ].freeze

    DECIMAL_FIELDS = (
      COLUMN_MAP.values -
      INTEGER_FIELDS -
      %i[state_code administrative_dependency]
    ).freeze

    REQUIRED_HEADERS = COLUMN_MAP.keys.freeze

    attr_reader :path

    def initialize(path: DEFAULT_PATH)
      @path = Pathname(path)
    end

    def call
      validate_file!

      now = Time.current
      rows = []

      csv = CSV.foreach(
        path,
        headers: true,
        encoding: "bom|utf-8"
      )

      headers_checked = false

      csv.each_with_index do |row, index|
        unless headers_checked
          validate_headers!(row.headers)
          headers_checked = true
        end

        attrs = normalize_row(row)

        validate_row!(attrs, index + 2)

        attrs[:created_at] = now
        attrs[:updated_at] = now

        rows << attrs
      end

      EnemStateResult.transaction do
        EnemStateResult.upsert_all(
          rows,
          unique_by: :idx_enem_state_results_unique
        )
      end

      {
        processed: rows.size,
        persisted: EnemStateResult.count,
        years: EnemStateResult.distinct.order(:year).pluck(:year),
        states: EnemStateResult.distinct.order(:state_code).pluck(:state_code),
        dependencies: EnemStateResult.distinct
                                     .order(:administrative_dependency)
                                     .pluck(:administrative_dependency)
      }
    end

    private

    def validate_file!
      return if path.exist?

      raise ArgumentError, "Arquivo ENEM não encontrado: #{path}"
    end

    def validate_headers!(headers)
      missing = REQUIRED_HEADERS - headers

      return if missing.empty?

      raise ArgumentError,
            "CSV ENEM sem as colunas obrigatórias: #{missing.join(', ')}"
    end

    def normalize_row(row)
      COLUMN_MAP.each_with_object({}) do |(csv_name, attribute), attrs|
        raw = row[csv_name]

        attrs[attribute] =
          if INTEGER_FIELDS.include?(attribute)
            integer_value(raw)
          elsif DECIMAL_FIELDS.include?(attribute)
            decimal_value(raw)
          else
            string_value(raw)
          end
      end
    end

    def integer_value(value)
      return 0 if value.nil? || value.to_s.strip.empty?

      Integer(value.to_s.strip)
    rescue ArgumentError
      raise ArgumentError, "Valor inteiro inválido: #{value.inspect}"
    end

    def decimal_value(value)
      return nil if value.nil? || value.to_s.strip.empty?

      normalized = value.to_s.strip.tr(",", ".")
      BigDecimal(normalized)
    rescue ArgumentError
      raise ArgumentError, "Valor decimal inválido: #{value.inspect}"
    end

    def string_value(value)
      value.to_s.strip.presence
    end

    def validate_row!(attrs, line_number)
      year = attrs[:year]
      state = attrs[:state_code]
      dependency = attrs[:administrative_dependency]

      unless (2016..2025).cover?(year)
        raise ArgumentError,
              "Linha #{line_number}: ano inválido #{year.inspect}"
      end

      if state.blank?
        raise ArgumentError,
              "Linha #{line_number}: SG_UF_ESC vazio"
      end

      unless EnemStateResult::DEPENDENCIES.include?(dependency)
        raise ArgumentError,
              "Linha #{line_number}: dependência inválida #{dependency.inspect}"
      end
    end
  end
end
