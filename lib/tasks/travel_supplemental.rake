namespace :travel_data do
  desc "Importa dados consolidados, hospedagens e translados de db/import_data/travel"
  task import_supplemental: :environment do
    result = LongTrips::SupplementalDataImporter.new.call
    puts "Carga complementar concluída:"
    puts "  Viagens consolidadas: #{result[:travel_summaries]}"
    puts "  Hospedagens: #{result[:travel_accommodations]}"
    puts "  Translados: #{result[:travel_transfers]}"
  end
end
