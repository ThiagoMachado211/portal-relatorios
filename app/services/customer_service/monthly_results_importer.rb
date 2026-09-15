require "csv"

module CustomerService
  class MonthlyResultsImporter
    class Error < StandardError; end

    MONTHS = {
      "Jan" => 1, "Fev" => 2, "Mar" => 3, "Abr" => 4,
      "Mai" => 5, "Jun" => 6, "Jul" => 7, "Ago" => 8,
      "Set" => 9, "Out" => 10, "Nov" => 11, "Dez" => 12
    }.freeze

    COUNT_COLUMNS = {
      output_count: "SAÍDA",
      responses_count: "RESPOSTAS",
      first_responses_count: "PRIMEIRAS RESPOSTAS",
      fcr_tickets_count: "TÍQUETES FCR",
      closed_tickets_count: "TÍQUETES FECHADOS",
      reopened_tickets_count: "TÍQUETES REABERTOS"
    }.freeze

    TIME_METRICS = {
      avg_first_response_seconds: {
        time_column: "TEMPO DE PRIMEIRA RESPOSTA (MÉD)",
        weight_column: "PRIMEIRAS RESPOSTAS"
      },
      avg_response_seconds: {
        time_column: "TEMPO DE RESPOSTA (MÉD)",
        weight_column: "RESPOSTAS"
      },
      avg_resolution_seconds: {
        time_column: "TEMPO DE RESOLUÇÃO (MÉD)",
        weight_column: "TÍQUETES FECHADOS"
      }
    }.freeze

    REQUIRED_COLUMNS = (
      ["AGENTE"] + COUNT_COLUMNS.values +
      TIME_METRICS.values.flat_map { |config| [config[:time_column], config[:weight_column]] }
    ).uniq.freeze

    def initialize(directory: Rails.root.join("db", "import_data", "customer_service"))
      @directory = Pathname.new(directory)
    end

    def import_all!
      files = Dir[@directory.join("Suporte_*26.csv")].sort
      raise Error, "Nenhum CSV de atendimento encontrado em #{@directory}." if files.empty?

      files.map { |path| import_file!(path) }
    end

    def import_file!(path)
      path = Pathname.new(path)
      year, month = period_from_filename(path.basename.to_s)
      rows = read_agent_rows(path)
      attributes = summarize(rows).merge(
        year: year,
        month: month,
        source_filename: path.basename.to_s
      )

      record = CustomerServiceMonthlyResult.find_or_initialize_by(year: year, month: month)
      record.assign_attributes(attributes)
      record.save!
      record
    end

    def summarize(rows)
      counts = COUNT_COLUMNS.to_h do |attribute, column|
        [attribute, rows.sum { |row| integer_value(row[column]) }]
      end

      times = TIME_METRICS.to_h do |attribute, config|
        [attribute, weighted_average_seconds(
          rows,
          time_column: config[:time_column],
          weight_column: config[:weight_column]
        )]
      end

      counts.merge(times)
    end

    private

    def read_agent_rows(path)
      content = File.read(path, encoding: "bom|utf-8")
      lines = content.lines
      raise Error, "Arquivo #{path.basename} não possui o cabeçalho esperado." if lines.length < 5

      table = CSV.parse(lines.drop(3).join, headers: true)
      missing = REQUIRED_COLUMNS - table.headers.compact

      if missing.any?
        raise Error, "Colunas ausentes em #{path.basename}: #{missing.join(', ')}"
      end

      table.reject { |row| row["AGENTE"].to_s.strip.empty? }
    rescue CSV::MalformedCSVError => e
      raise Error, "CSV inválido em #{path.basename}: #{e.message}"
    end

    def period_from_filename(filename)
      match = filename.match(/\ASuporte_([A-Za-z]{3})(\d{2})\.csv\z/i)
      raise Error, "Nome de arquivo inválido: #{filename}" unless match

      month_token = match[1].capitalize
      month = MONTHS[month_token]
      raise Error, "Mês não reconhecido no arquivo: #{filename}" unless month

      [2000 + match[2].to_i, month]
    end

    def integer_value(value)
      value.to_s.strip.gsub(/[.\s]/, "").to_i
    end

    def weighted_average_seconds(rows, time_column:, weight_column:)
      weighted_sum = 0.0
      valid_weight = 0

      rows.each do |row|
        weight = integer_value(row[weight_column])
        seconds = duration_to_seconds(row[time_column])

        next if weight <= 0 || seconds.nil?

        weighted_sum += seconds * weight
        valid_weight += weight
      end

      return nil if valid_weight.zero?

      (weighted_sum / valid_weight).round
    end

    def duration_to_seconds(value)
      text = value.to_s.strip
      return nil if text.empty? || text == "-"

      total = 0

      if (days = text.match(/(\d+)d/i))
        total += days[1].to_i * 86_400
      end

      if text.include?(":")
        clock = text.match(/(\d+):(\d{2}):(\d{2})/)
        raise Error, "Duração não reconhecida: #{text}" unless clock

        total += clock[1].to_i * 3_600
        total += clock[2].to_i * 60
        total += clock[3].to_i
      else
        total += text.match(/(\d+)h/i)[1].to_i * 3_600 if text.match?(/(\d+)h/i)
        total += text.match(/(\d+)m/i)[1].to_i * 60 if text.match?(/(\d+)m/i)
        total += text.match(/(\d+)s/i)[1].to_i if text.match?(/(\d+)s/i)
      end

      total
    end
  end
end
