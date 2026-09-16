module CustomerService
  class DashboardData
    DEFAULT_VIEW = "overview"

    METRICS = {
      "fcr_tickets" => {
        label: "Tíquetes FCR",
        short_label: "Tíquetes FCR",
        attribute: :fcr_tickets_count,
        format: :count
      },
      "closed_tickets" => {
        label: "Tíquetes Fechados",
        short_label: "Tíquetes Fechados",
        attribute: :closed_tickets_count,
        format: :count
      },
      "avg_first_response" => {
        label: "Tempo de Primeira Resposta (Méd)",
        short_label: "Tempo 1ª Resposta",
        attribute: :avg_first_response_seconds,
        format: :duration
      },
      "avg_response" => {
        label: "Tempo de Resposta (Méd)",
        short_label: "Tempo de Resposta",
        attribute: :avg_response_seconds,
        format: :duration
      },
      "avg_resolution" => {
        label: "Tempo de Resolução (Méd)",
        short_label: "Tempo de Resolução",
        attribute: :avg_resolution_seconds,
        format: :duration
      },
      "ok_classifications" => {
        label: "Classificações Ok",
        short_label: "Classificações Ok",
        attribute: :ok_classifications_count,
        format: :count
      },
      "bad_classifications" => {
        label: "Classificações Ruins",
        short_label: "Classificações Ruins",
        attribute: :bad_classifications_count,
        format: :count
      },
      "good_classifications" => {
        label: "Boas Classificações",
        short_label: "Boas Classificações",
        attribute: :good_classifications_count,
        format: :count
      }
    }.freeze

    NAVIGATION = { "overview" => "Visão Geral" }
                 .merge(METRICS.transform_values { |config| config[:short_label] })
                 .freeze

    def initialize(view:)
      candidate = view.to_s
      @view = NAVIGATION.key?(candidate) ? candidate : DEFAULT_VIEW
    end

    def call
      rows = CustomerServiceMonthlyResult.chronological.to_a
      latest = rows.last

      {
        navigation: NAVIGATION,
        current_view: @view,
        latest: latest,
        period_label: period_label(rows),
        overview: overview(latest),
        selected_metric: selected_metric,
        evolution: evolution(rows)
      }
    end

    private

    def overview(record)
      return [] unless record

      METRICS.map do |key, config|
        {
          key: key,
          label: config[:label],
          value: record.public_send(config[:attribute]),
          format: config[:format]
        }
      end
    end

    def selected_metric
      return nil if @view == DEFAULT_VIEW

      METRICS.fetch(@view)
    end

    def evolution(rows)
      return nil unless selected_metric

      attribute = selected_metric[:attribute]

      {
        label: selected_metric[:label],
        format: selected_metric[:format],
        labels: rows.map(&:month_label),
        values: rows.map { |row| row.public_send(attribute) }
      }
    end

    def period_label(rows)
      return "Sem dados" if rows.empty?
      return rows.first.month_label if rows.one?

      "#{rows.first.month_label} — #{rows.last.month_label}"
    end
  end
end
