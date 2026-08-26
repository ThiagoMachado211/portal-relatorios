class CalendarData
  def self.mg_items
    [
      {
        test_name: "1º Simulado ENEM",
        test_type: "Simulado",
        print_file_date: Date.parse("2026-02-20"),
        upload_start_date: Date.parse("2026-04-14"),
        upload_end_date: Date.parse("2026-04-28"),
        result_date: Date.parse("2026-05-15"),
        print_type: "Gráfica"
      },
      {
        test_name: "1º Teste de Redação",
        test_type: "Teste de Redação",
        print_file_date: Date.parse("2026-03-16"),
        upload_start_date: Date.parse("2026-03-25"),
        upload_end_date: Date.parse("2026-04-06"),
        result_date: Date.parse("2026-04-20"),
        print_type: "Escola"
      },
      {
        test_name: "2º Teste de Redação",
        test_type: "Teste de Redação",
        print_file_date: Date.parse("2026-06-08"),
        upload_start_date: Date.parse("2026-06-17"),
        upload_end_date: Date.parse("2026-06-29"),
        result_date: Date.parse("2026-07-10"),
        print_type: "Escola"
      },
      {
        test_name: "2º Simulado ENEM",
        test_type: "Simulado",
        print_file_date: Date.parse("2026-07-13"),
        upload_start_date: Date.parse("2026-08-25"),
        upload_end_date: Date.parse("2026-09-11"),
        result_date: Date.parse("2026-09-30"),
        print_type: "Gráfica"
      },
      {
        test_name: "3º Teste de Redação",
        test_type: "Teste de Redação",
        print_file_date: Date.parse("2026-09-25"),
        upload_start_date: Date.parse("2026-10-08"),
        upload_end_date: Date.parse("2026-10-21"),
        result_date: Date.parse("2026-11-06"),
        print_type: "Escola"
      }
    ]
  end
end