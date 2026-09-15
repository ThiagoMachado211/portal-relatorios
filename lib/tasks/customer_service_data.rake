namespace :customer_service_data do
  desc "Importa e consolida os CSVs mensais do Atendimento ao Cliente"
  task import: :environment do
    puts "Importando dados de Atendimento ao Cliente..."

    records = CustomerService::MonthlyResultsImporter.new.import_all!

    records.sort_by { |record| [record.year, record.month] }.each do |record|
      puts format(
        "%s | respostas=%d | primeiras=%d | FCR=%d | fechados=%d | reabertos=%d",
        record.month_label,
        record.responses_count,
        record.first_responses_count,
        record.fcr_tickets_count,
        record.closed_tickets_count,
        record.reopened_tickets_count
      )
    end

    puts "OK — #{records.size} meses importados/consolidados."
  end
end
