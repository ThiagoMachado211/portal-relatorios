namespace :import do
  desc "Importa a aba TRECHOS_LONGOS para LongTrip"
  task long_trips: :environment do
    file_path = ENV["FILE"]

    if file_path.blank?
      puts "Use assim: bin/rails import:long_trips FILE=caminho/para/arquivo.xlsx"
      exit
    end

    importer = LongTripsImporter.new(file_path).call

    puts "Importação concluída."
    puts "Registros importados: #{importer.imported_count}"

    if importer.errors.any?
      puts "Erros encontrados:"
      importer.errors.each do |error|
        puts "Linha #{error[:row]} - #{error[:traveler_name]}: #{error[:messages].join(', ')}"
      end
    else
      puts "Nenhum erro encontrado."
    end
  end
end