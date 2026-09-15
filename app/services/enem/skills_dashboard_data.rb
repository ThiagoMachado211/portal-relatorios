module Enem
  class SkillsDashboardData
    DEFAULT_VIEW = "distribution"
    DEFAULT_AREA = "CH"
    DEFAULT_LANGUAGE = "ingles"
    DEFAULT_UF = "BRASIL"
    DEFAULT_DEPENDENCY = "TODAS"

    VIEWS = {
      "distribution" => "Distribuição na prova",
      "history" => "Evolução e desempenho"
    }.freeze

    AREA_NAMES = {
      "CH" => "Ciências Humanas e suas Tecnologias",
      "CN" => "Ciências da Natureza e suas Tecnologias",
      "LC" => "Linguagens, Códigos e suas Tecnologias",
      "MT" => "Matemática e suas Tecnologias"
    }.freeze

    LANGUAGES = {
      "ingles" => "Inglês",
      "espanhol" => "Espanhol"
    }.freeze

    def initialize(view:, year:, area:, language:, skill_code:, uf:, dependency:)
      @years = EnemSkillDistribution.distinct.order(year: :desc).pluck(:year)
      @areas = EnemSkill.distinct.order(:area).pluck(:area)
      @ufs = load_ufs
      @dependencies = EnemSkillResult.distinct.order(:dependency).pluck(:dependency)

      @view = VIEWS.key?(view.to_s) ? view.to_s : DEFAULT_VIEW
      @year = normalize_year(year)
      @area = normalize_area(area)
      @language = LANGUAGES.key?(language.to_s) ? language.to_s : DEFAULT_LANGUAGE
      @skill_code = normalize_skill(skill_code)
      @uf = @ufs.include?(uf.to_s.upcase) ? uf.to_s.upcase : DEFAULT_UF
      @dependency = @dependencies.include?(dependency.to_s.upcase) ? dependency.to_s.upcase : DEFAULT_DEPENDENCY
    end

    def call
      {
        current_view: @view,
        navigation: VIEWS,
        filters: filters,
        filter_options: filter_options,
        distribution: distribution,
        selected_skill: selected_skill,
        presence_history: presence_history,
        performance_history: performance_history,
        summary: summary
      }
    end

    private

    def filters
      {
        year: @year,
        area: @area,
        language: @language,
        skill_code: @skill_code,
        uf: @uf,
        dependency: @dependency
      }
    end

    def filter_options
      {
        years: @years,
        areas: @areas.map { |code| [AREA_NAMES.fetch(code, code), code] },
        languages: LANGUAGES.map { |code, label| [label, code] },
        skills: skills_for_area.map { |skill| ["H#{skill.skill_code} — #{skill.skill_description}", skill.skill_code] },
        ufs: @ufs,
        dependencies: @dependencies
      }
    end

    def load_ufs
      values = EnemSkillResult.distinct.pluck(:uf).compact.map(&:upcase).uniq.sort
      values.delete(DEFAULT_UF)
      [DEFAULT_UF] + values
    end

    def normalize_year(value)
      candidate = value.to_i
      @years.include?(candidate) ? candidate : (@years.first || 2025)
    end

    def normalize_area(value)
      candidate = value.to_s.upcase
      @areas.include?(candidate) ? candidate : (@areas.include?(DEFAULT_AREA) ? DEFAULT_AREA : @areas.first)
    end

    def normalize_skill(value)
      available = skills_for_area.map(&:skill_code)
      candidate = value.to_i
      available.include?(candidate) ? candidate : (available.first || 1)
    end

    def skills_for_area
      @skills_for_area ||= EnemSkill.where(area: @area).order(:skill_code).to_a
    end

    def skill_lookup
      @skill_lookup ||= skills_for_area.index_by(&:skill_code)
    end

    def distribution
      EnemSkillDistribution
        .where(year: @year, area: @area)
        .order(:skill_code)
        .map do |row|
          skill = skill_lookup[row.skill_code]
          count, percentage = distribution_values(row)

          {
            skill_code: row.skill_code,
            label: row.skill_code.zero? ? "H0" : "H#{row.skill_code}",
            status: row.skill_status,
            question_count: decimal(count),
            percentage: percentage_value(percentage),
            competency_code: skill&.competency_code || row.competency_code,
            competency_description: skill&.competency_description || "Não se aplica",
            skill_description: skill&.skill_description || "Habilidade não informada nos microdados"
          }
        end
    end

    def distribution_values(row)
      return [row.question_count, row.question_percentage] unless @area == "LC"

      if @language == "espanhol"
        [row.spanish_question_count, row.spanish_question_percentage]
      else
        [row.english_question_count, row.english_question_percentage]
      end
    end

    def selected_skill
      skill = skill_lookup[@skill_code]
      return nil unless skill

      {
        area: skill.area,
        area_name: skill.area_name.presence || AREA_NAMES[skill.area],
        skill_code: skill.skill_code,
        label: "H#{skill.skill_code}",
        description: skill.skill_description,
        competency_code: skill.competency_code,
        competency_description: skill.competency_description
      }
    end

    def presence_history
      rows = EnemSkillDistribution
        .where(area: @area, skill_code: @skill_code)
        .order(:year)
        .index_by(&:year)

      @years.sort.map do |year|
        row = rows[year]
        count, percentage = row ? distribution_values(row) : [nil, nil]

        {
          year: year,
          question_count: decimal(count),
          percentage: percentage_value(percentage)
        }
      end
    end

    def performance_history
      rows = EnemSkillResult
        .where(
          area: @area,
          skill_code: @skill_code,
          uf: @uf,
          dependency: @dependency
        )
        .order(:year)
        .index_by(&:year)

      @years.sort.map do |year|
        row = rows[year]
        {
          year: year,
          correct_rate: percentage_value(row&.correct_rate),
          participants: row&.participant_count,
          responses: row&.response_count,
          correct: row&.correct_count,
          items: row&.item_count
        }
      end
    end

    def summary
      values = performance_history.filter_map { |row| row[:correct_rate] }
      presence = presence_history.filter_map { |row| row[:percentage] }

      {
        latest_correct_rate: performance_history.reverse.find { |row| row[:correct_rate] }&.dig(:correct_rate),
        average_correct_rate: values.any? ? values.sum / values.size : nil,
        years_present: presence.count { |value| value.positive? },
        average_presence: presence.any? ? presence.sum / presence.size : nil
      }
    end

    def decimal(value)
      value.nil? ? nil : value.to_f
    end

    def percentage_value(value)
      value.nil? ? nil : value.to_f * 100.0
    end
  end
end
