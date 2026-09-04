namespace :enem_data do
  desc "Importa a base ENEM agregada por estado/dependência de 2016 a 2025"
  task import_states: :environment do
    result = Enem::StateResultsImporter.new.call

    puts
    puts "Importação ENEM concluída."
    puts "Linhas processadas: #{result[:processed]}"
    puts "Registros no banco: #{result[:persisted]}"
    puts "Anos: #{result[:years].join(', ')}"
    puts "Dependências: #{result[:dependencies].join(', ')}"
    puts "UFs/categorias geográficas: #{result[:states].size}"
    puts
  end

  desc "Mostra uma conferência resumida da base ENEM importada"
  task verify_states: :environment do
    puts
    puts "ENEM — conferência da base"
    puts "-" * 60
    puts "Total de registros: #{EnemStateResult.count}"
    puts "Anos: #{EnemStateResult.distinct.order(:year).pluck(:year).inspect}"
    puts "Dependências: #{EnemStateResult.distinct.order(:administrative_dependency).pluck(:administrative_dependency).inspect}"
    puts "Geografias: #{EnemStateResult.distinct.count(:state_code)}"

    puts
    puts "Registros por ano:"
    EnemStateResult.group(:year).order(:year).count.each do |year, count|
      puts "  #{year}: #{count}"
    end

    puts
    puts "Brasil por ano/dependência:"
    EnemStateResult.where(state_code: "Brasil")
                   .group(:year)
                   .order(:year)
                   .count
                   .each do |year, count|
      puts "  #{year}: #{count}"
    end

    duplicates =
      EnemStateResult
        .group(:year, :state_code, :administrative_dependency)
        .having("COUNT(*) > 1")
        .count

    puts
    puts "Duplicidades na chave ano/UF/dependência: #{duplicates.size}"

    invalid_pct =
      EnemStateResult.where(
        "participation_day1_pct < 0 OR participation_day1_pct > 100 OR " \
        "participation_day2_pct < 0 OR participation_day2_pct > 100 OR " \
        "participation_both_days_pct < 0 OR participation_both_days_pct > 100"
      ).count

    puts "Registros com participação fora de 0–100%: #{invalid_pct}"

    puts
  end
end
