require "csv"

module Enem
  class SkillDataImporter
    DATA_DIR = Rails.root.join("db", "import_data", "enem")

    SKILLS_FILE        = DATA_DIR.join("enem_skills.csv")
    DISTRIBUTIONS_FILE = DATA_DIR.join("enem_skill_distributions.csv")
    RESULTS_FILE       = DATA_DIR.join("enem_skill_results.csv")

    BATCH_SIZE = 5_000

    def self.call
      new.call
    end

    def call
      puts "=" * 70
      puts "IMPORTAÇÃO ENEM — HABILIDADES — FASE 2"
      puts "=" * 70

      validate_files!

      import_skills
      import_distributions
      import_results

      validate_import!

      puts
      puts "=" * 70
      puts "IMPORTAÇÃO CONCLUÍDA"
      puts "=" * 70

      print_counts
    end

    private

    # ---------------------------------------------------------
    # ARQUIVOS
    # ---------------------------------------------------------

    def validate_files!
      [
        SKILLS_FILE,
        DISTRIBUTIONS_FILE,
        RESULTS_FILE
      ].each do |file|
        raise "Arquivo não encontrado: #{file}" unless File.exist?(file)
      end

      puts "\nArquivos encontrados: OK"
    end

    # ---------------------------------------------------------
    # DIMENSÃO
    # ---------------------------------------------------------

    def import_skills
      puts "\nImportando habilidades..."

      rows = []

      CSV.foreach(
        SKILLS_FILE,
        headers: true,
        encoding: "bom|utf-8"
      ) do |row|
        rows << {
          area: row["area"],
          name: row["name"],
          area_name: row["area_name"],
          competency_code: integer_or_nil(row["competency_code"]),
          competency_description: row["competency_description"],
          skill_code: integer_or_nil(row["skill_code"]),
          skill_description: row["skill_description"],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      EnemSkill.transaction do
        EnemSkill.delete_all
        EnemSkill.insert_all!(rows)
      end

      puts "Habilidades importadas: #{EnemSkill.count}"
    end

    # ---------------------------------------------------------
    # DISTRIBUIÇÃO
    # ---------------------------------------------------------

    def import_distributions
      puts "\nImportando distribuição das habilidades..."

      EnemSkillDistribution.transaction do
        EnemSkillDistribution.delete_all

        each_csv_batch(DISTRIBUTIONS_FILE) do |batch|
          rows = batch.map do |row|
            {
              year: integer_or_nil(row["year"]),
              area: row["area"],
              competency_code: integer_or_nil(row["competency_code"]),
              skill_code: integer_or_nil(row["skill_code"]),
              skill_status: row["skill_status"],

              question_count: decimal_or_nil(row["question_count"]),
              question_percentage:
                decimal_or_nil(row["question_percentage"]),

              english_question_count:
                decimal_or_nil(row["english_question_count"]),
              english_question_percentage:
                decimal_or_nil(row["english_question_percentage"]),

              spanish_question_count:
                decimal_or_nil(row["spanish_question_count"]),
              spanish_question_percentage:
                decimal_or_nil(row["spanish_question_percentage"]),

              total_area_questions:
                integer_or_nil(row["total_area_questions"]),

              created_at: Time.current,
              updated_at: Time.current
            }
          end

          EnemSkillDistribution.insert_all!(rows)
        end
      end

      puts "Distribuições importadas: #{EnemSkillDistribution.count}"
    end

    # ---------------------------------------------------------
    # DESEMPENHO
    # ---------------------------------------------------------

    def import_results
      puts "\nImportando desempenho das habilidades..."

      EnemSkillResult.transaction do
        EnemSkillResult.delete_all

        each_csv_batch(RESULTS_FILE) do |batch|
          rows = batch.map do |row|
            {
              year: integer_or_nil(row["year"]),
              uf: row["uf"],
              dependency: row["dependency"],
              area: row["area"],

              competency_code:
                integer_or_nil(row["competency_code"]),
              skill_code:
                integer_or_nil(row["skill_code"]),
              skill_status:
                row["skill_status"],

              item_count:
                integer_or_nil(row["item_count"]),
              participant_count:
                integer_or_nil(row["participant_count"]),
              response_count:
                integer_or_nil(row["response_count"]),
              correct_count:
                integer_or_nil(row["correct_count"]),
              correct_rate:
                decimal_or_nil(row["correct_rate"]),

              created_at: Time.current,
              updated_at: Time.current
            }
          end

          EnemSkillResult.insert_all!(rows)
        end
      end

      puts "Resultados importados: #{EnemSkillResult.count}"
    end

    # ---------------------------------------------------------
    # LEITURA EM LOTES
    # ---------------------------------------------------------

    def each_csv_batch(file)
      batch = []

      CSV.foreach(
        file,
        headers: true,
        encoding: "bom|utf-8"
      ) do |row|

        batch << row

        if batch.size >= BATCH_SIZE
          yield batch
          batch = []
        end
      end

      yield batch if batch.any?
    end

    # ---------------------------------------------------------
    # CONVERSÕES
    # ---------------------------------------------------------

    def integer_or_nil(value)
      return nil if blank_value?(value)

      value.to_f.to_i
    end

    def decimal_or_nil(value)
      return nil if blank_value?(value)

      BigDecimal(value)
    end

    def blank_value?(value)
      value.nil? ||
        value.strip.empty? ||
        value.strip.downcase == "nan"
    end

    # ---------------------------------------------------------
    # VALIDAÇÃO
    # ---------------------------------------------------------

    def validate_import!
      errors = []

      errors << "enem_skills deveria possuir 120 linhas." \
        unless EnemSkill.count == 120

      errors << "enem_skill_distributions deveria possuir 1.189 linhas." \
        unless EnemSkillDistribution.count == 1_189

      errors << "enem_skill_results deveria possuir 160.998 linhas." \
        unless EnemSkillResult.count == 160_998

      official_skills = EnemSkill
        .group(:area)
        .count

      expected = {
        "CH" => 30,
        "CN" => 30,
        "LC" => 30,
        "MT" => 30
      }

      errors << "Quantidade de habilidades oficiais por área incorreta." \
        unless official_skills == expected

      h0 = EnemSkillDistribution.where(
        year: 2021,
        area: "MT",
        skill_code: 0
      )

      errors << "H0 de MT/2021 não foi encontrada." \
        unless h0.count == 1

      raise errors.join("\n") if errors.any?

      puts "\nValidação da importação: OK"
    end

    def print_counts
      puts "enem_skills:              #{EnemSkill.count}"
      puts "enem_skill_distributions: #{EnemSkillDistribution.count}"
      puts "enem_skill_results:        #{EnemSkillResult.count}"
    end
  end
end