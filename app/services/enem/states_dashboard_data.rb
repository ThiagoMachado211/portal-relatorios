module Enem
  class StatesDashboardData
    DEFAULT_YEAR = 2025
    DEFAULT_STATE = "Brasil"
    DEFAULT_DEPENDENCY = "Estadual"
    DEFAULT_VIEW = "overview"
    DEFAULT_EVOLUTION_METRIC = "general_average"
    DEFAULT_RANKING_METRIC = "general_average"

    VIEWS = {
      "overview" => "Visão Geral",
      "participation" => "Participação",
      "performance" => "Desempenho",
      "essay" => "Redação",
      "competencies" => "Competências",
      "status" => "Status da Redação",
      "evolution" => "Evolução Histórica",
      "ranking" => "Ranking dos Estados"
    }.freeze

    METRICS = {
      "participation_day1_pct" => {
        label: "Participação — Dia 1 (%)",
        attribute: :participation_day1_pct,
        format: :percentage,
        higher_is_better: true
      },
      "participation_day2_pct" => {
        label: "Participação — Dia 2 (%)",
        attribute: :participation_day2_pct,
        format: :percentage,
        higher_is_better: true
      },
      "participation_both_days_pct" => {
        label: "Participação — D1 + D2 (%)",
        attribute: :participation_both_days_pct,
        format: :percentage,
        higher_is_better: true
      },
      "human_sciences_average" => {
        label: "Ciências Humanas",
        attribute: :human_sciences_average,
        format: :score,
        higher_is_better: true
      },
      "languages_average" => {
        label: "Linguagens",
        attribute: :languages_average,
        format: :score,
        higher_is_better: true
      },
      "natural_sciences_average" => {
        label: "Ciências da Natureza",
        attribute: :natural_sciences_average,
        format: :score,
        higher_is_better: true
      },
      "mathematics_average" => {
        label: "Matemática",
        attribute: :mathematics_average,
        format: :score,
        higher_is_better: true
      },
      "essay_average" => {
        label: "Redação",
        attribute: :essay_average,
        format: :score,
        higher_is_better: true
      },
      "general_average" => {
        label: "Média Geral",
        attribute: :general_average,
        format: :score,
        higher_is_better: true
      },
      "essay_competency_1_average" => {
        label: "Competência 1",
        attribute: :essay_competency_1_average,
        format: :competency,
        higher_is_better: true
      },
      "essay_competency_2_average" => {
        label: "Competência 2",
        attribute: :essay_competency_2_average,
        format: :competency,
        higher_is_better: true
      },
      "essay_competency_3_average" => {
        label: "Competência 3",
        attribute: :essay_competency_3_average,
        format: :competency,
        higher_is_better: true
      },
      "essay_competency_4_average" => {
        label: "Competência 4",
        attribute: :essay_competency_4_average,
        format: :competency,
        higher_is_better: true
      },
      "essay_competency_5_average" => {
        label: "Competência 5",
        attribute: :essay_competency_5_average,
        format: :competency,
        higher_is_better: true
      },
      "essays_ok_pct" => {
        label: "Redações sem problemas (%)",
        attribute: :essays_ok_pct,
        format: :percentage,
        higher_is_better: true
      }
    }.freeze

    STATUS_FIELDS = [
      ["Sem problemas", :essays_ok_count, :essays_ok_pct],
      ["Anulada", :essays_annulled_count, :essays_annulled_pct],
      ["Cópia do texto motivador", :essays_motivating_text_copy_count, :essays_motivating_text_copy_pct],
      ["Em branco", :essays_blank_count, :essays_blank_pct],
      ["Fere Direitos Humanos", :essays_human_rights_violation_count, :essays_human_rights_violation_pct],
      ["Fuga ao tema", :essays_off_topic_count, :essays_off_topic_pct],
      ["Não atendimento ao tipo textual", :essays_wrong_text_type_count, :essays_wrong_text_type_pct],
      ["Texto insuficiente", :essays_insufficient_text_count, :essays_insufficient_text_pct],
      ["Parte desconectada", :essays_disconnected_part_count, :essays_disconnected_part_pct]
    ].freeze

    def initialize(year:, state_code:, dependency:, view:, evolution_metric:, ranking_metric:)
      @available_years = load_years
      @available_states = load_states
      @available_dependencies = load_dependencies

      @year = normalize_year(year)
      @state_code = normalize_state(state_code)
      @dependency = normalize_dependency(dependency)
      @view = VIEWS.key?(view.to_s) ? view.to_s : DEFAULT_VIEW
      @evolution_metric = METRICS.key?(evolution_metric.to_s) ? evolution_metric.to_s : DEFAULT_EVOLUTION_METRIC
      @ranking_metric = METRICS.key?(ranking_metric.to_s) ? ranking_metric.to_s : DEFAULT_RANKING_METRIC
    end

    def call
      {
        filters: filters,
        filter_options: filter_options,
        navigation: VIEWS,
        current_view: @view,
        record: record,
        kpis: kpis,
        participation: participation,
        performance: performance,
        competencies: competencies,
        essay_statuses: essay_statuses,
        evolution: evolution,
        ranking: ranking,
        metric_options: METRICS.transform_values { |config| config[:label] },
        evolution_metric: @evolution_metric,
        ranking_metric: @ranking_metric,
        evolution_metric_config: METRICS.fetch(@evolution_metric),
        ranking_metric_config: METRICS.fetch(@ranking_metric)
      }
    end

    private

    def filters
      {
        year: @year,
        state_code: @state_code,
        dependency: @dependency
      }
    end

    def filter_options
      {
        years: @available_years,
        states: @available_states,
        dependencies: @available_dependencies
      }
    end

    def load_years
      EnemStateResult.distinct.order(year: :desc).pluck(:year)
    end

    def load_states
      values = EnemStateResult.distinct.pluck(:state_code).compact.uniq.sort
      values.delete("Brasil")
      ["Brasil"] + values
    end

    def load_dependencies
      EnemStateResult::DEPENDENCIES
    end

    def normalize_year(value)
      candidate = value.to_i
      @available_years.include?(candidate) ? candidate : (@available_years.first || DEFAULT_YEAR)
    end

    def normalize_state(value)
      candidate = value.to_s.presence
      @available_states.include?(candidate) ? candidate : DEFAULT_STATE
    end

    def normalize_dependency(value)
      candidate = value.to_s.presence
      @available_dependencies.include?(candidate) ? candidate : DEFAULT_DEPENDENCY
    end

    def record
      @record ||= EnemStateResult.find_by(
        year: @year,
        state_code: @state_code,
        administrative_dependency: @dependency
      )
    end

    def kpis
      return {} unless record

      {
        registered_count: record.registered_count,
        participants_day1_count: record.participants_day1_count,
        participants_day2_count: record.participants_day2_count,
        participants_both_days_count: record.participants_both_days_count,
        participation_day1_pct: record.participation_day1_pct,
        participation_day2_pct: record.participation_day2_pct,
        participation_both_days_pct: record.participation_both_days_pct,
        general_average: record.general_average,
        essay_average: record.essay_average,
        essays_count: record.essays_count
      }
    end

    def participation
      return [] unless record

      [
        {
          label: "Dia 1",
          count: record.participants_day1_count,
          percentage: decimal(record.participation_day1_pct)
        },
        {
          label: "Dia 2",
          count: record.participants_day2_count,
          percentage: decimal(record.participation_day2_pct)
        },
        {
          label: "D1 + D2",
          count: record.participants_both_days_count,
          percentage: decimal(record.participation_both_days_pct)
        }
      ]
    end

    def performance
      return [] unless record

      [
        { label: "Ciências Humanas", short_label: "CH", value: decimal(record.human_sciences_average) },
        { label: "Linguagens", short_label: "LC", value: decimal(record.languages_average) },
        { label: "Ciências da Natureza", short_label: "CN", value: decimal(record.natural_sciences_average) },
        { label: "Matemática", short_label: "MT", value: decimal(record.mathematics_average) },
        { label: "Redação", short_label: "RED", value: decimal(record.essay_average) },
        { label: "Média Geral", short_label: "GERAL", value: decimal(record.general_average) }
      ]
    end

    def competencies
      return [] unless record

      [
        { label: "Competência 1", short_label: "C1", value: decimal(record.essay_competency_1_average) },
        { label: "Competência 2", short_label: "C2", value: decimal(record.essay_competency_2_average) },
        { label: "Competência 3", short_label: "C3", value: decimal(record.essay_competency_3_average) },
        { label: "Competência 4", short_label: "C4", value: decimal(record.essay_competency_4_average) },
        { label: "Competência 5", short_label: "C5", value: decimal(record.essay_competency_5_average) }
      ]
    end

    def essay_statuses
      return [] unless record

      STATUS_FIELDS.map do |label, count_field, pct_field|
        {
          label: label,
          count: record.public_send(count_field),
          percentage: decimal(record.public_send(pct_field))
        }
      end
    end

    def evolution
      config = METRICS.fetch(@evolution_metric)
      attribute = config[:attribute]

      rows = EnemStateResult
             .where(
               state_code: @state_code,
               administrative_dependency: @dependency
             )
             .order(:year)
             .pluck(:year, attribute)

      {
        label: config[:label],
        format: config[:format],
        labels: rows.map(&:first),
        values: rows.map { |(_, value)| decimal(value) }
      }
    end

    def ranking
      config = METRICS.fetch(@ranking_metric)
      attribute = config[:attribute]

      rows = EnemStateResult
             .where(
               year: @year,
               administrative_dependency: @dependency
             )
             .where.not(state_code: "Brasil")
             .where.not(attribute => nil)
             .order(Arel.sql("#{EnemStateResult.connection.quote_column_name(attribute)} DESC"))
             .pluck(:state_code, attribute)

      items = rows.each_with_index.map do |(state_code, value), index|
        {
          position: index + 1,
          state_code: state_code,
          value: decimal(value),
          selected: state_code == @state_code
        }
      end

      {
        label: config[:label],
        format: config[:format],
        items: items,
        selected_position: items.find { |item| item[:selected] }&.dig(:position)
      }
    end

    def decimal(value)
      value.nil? ? nil : value.to_f.round(2)
    end
  end
end
