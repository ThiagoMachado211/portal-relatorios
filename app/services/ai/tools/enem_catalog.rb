module Ai
  module Tools
    class EnemCatalog
      METRICS = {
        # Participação
        "registered_count" => {
          label: "Inscritos",
          format: :integer
        },
        "participants_day1_count" => {
          label: "Participantes — Dia 1",
          format: :integer
        },
        "participants_day2_count" => {
          label: "Participantes — Dia 2",
          format: :integer
        },
        "participants_both_days_count" => {
          label: "Participantes — dois dias",
          format: :integer
        },
        "participation_day1_pct" => {
          label: "Participação — Dia 1",
          format: :percentage
        },
        "participation_day2_pct" => {
          label: "Participação — Dia 2",
          format: :percentage
        },
        "participation_both_days_pct" => {
          label: "Participação — dois dias",
          format: :percentage
        },

        # Desempenho
        "human_sciences_average" => {
          label: "Ciências Humanas",
          format: :decimal
        },
        "languages_average" => {
          label: "Linguagens",
          format: :decimal
        },
        "natural_sciences_average" => {
          label: "Ciências da Natureza",
          format: :decimal
        },
        "mathematics_average" => {
          label: "Matemática",
          format: :decimal
        },
        "essay_average" => {
          label: "Redação",
          format: :decimal
        },
        "general_average" => {
          label: "Média Geral",
          format: :decimal
        },

        # Competências da redação
        "essay_competency_1_average" => {
          label: "Competência 1 da Redação",
          format: :decimal
        },
        "essay_competency_2_average" => {
          label: "Competência 2 da Redação",
          format: :decimal
        },
        "essay_competency_3_average" => {
          label: "Competência 3 da Redação",
          format: :decimal
        },
        "essay_competency_4_average" => {
          label: "Competência 4 da Redação",
          format: :decimal
        },
        "essay_competency_5_average" => {
          label: "Competência 5 da Redação",
          format: :decimal
        },

        # Redações
        "essays_count" => {
          label: "Total de Redações",
          format: :integer
        },

        # Status — quantidades
        "essays_ok_count" => {
          label: "Redações OK",
          format: :integer
        },
        "essays_annulled_count" => {
          label: "Redações Anuladas",
          format: :integer
        },
        "essays_motivating_text_copy_count" => {
          label: "Cópia do Texto Motivador",
          format: :integer
        },
        "essays_blank_count" => {
          label: "Redações em Branco",
          format: :integer
        },
        "essays_human_rights_violation_count" => {
          label: "Violação dos Direitos Humanos",
          format: :integer
        },
        "essays_off_topic_count" => {
          label: "Fuga ao Tema",
          format: :integer
        },
        "essays_wrong_text_type_count" => {
          label: "Tipo Textual Incorreto",
          format: :integer
        },
        "essays_insufficient_text_count" => {
          label: "Texto Insuficiente",
          format: :integer
        },
        "essays_disconnected_part_count" => {
          label: "Parte Desconectada",
          format: :integer
        },

        # Status — percentuais
        "essays_ok_pct" => {
          label: "Percentual de Redações OK",
          format: :percentage
        },
        "essays_annulled_pct" => {
          label: "Percentual de Redações Anuladas",
          format: :percentage
        },
        "essays_motivating_text_copy_pct" => {
          label: "Percentual de Cópia do Texto Motivador",
          format: :percentage
        },
        "essays_blank_pct" => {
          label: "Percentual de Redações em Branco",
          format: :percentage
        },
        "essays_human_rights_violation_pct" => {
          label: "Percentual de Violação dos Direitos Humanos",
          format: :percentage
        },
        "essays_off_topic_pct" => {
          label: "Percentual de Fuga ao Tema",
          format: :percentage
        },
        "essays_wrong_text_type_pct" => {
          label: "Percentual de Tipo Textual Incorreto",
          format: :percentage
        },
        "essays_insufficient_text_pct" => {
          label: "Percentual de Texto Insuficiente",
          format: :percentage
        },
        "essays_disconnected_part_pct" => {
          label: "Percentual de Parte Desconectada",
          format: :percentage
        }
      }.freeze

      def self.fetch(metric)
        METRICS[metric.to_s]
      end

      def self.valid?(metric)
        METRICS.key?(metric.to_s)
      end

      def self.names
        METRICS.keys
      end
    end
  end
end