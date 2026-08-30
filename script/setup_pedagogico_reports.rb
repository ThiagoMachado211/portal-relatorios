# script/setup_pedagogico_reports.rb
#
# Execute com:
# ruby bin\rails runner script/setup_pedagogico_reports.rb
#
# Script idempotente:
# - garante a seção "Pedagógico"
# - garante as subseções ENEM, IDEB/SAEB e Avaliações Internas
# - não apaga registros existentes

section =
  SidebarSection.find_or_initialize_by(slug: "setor-pedagogico")

section.title = "Pedagógico"
section.position = 2 if section.position.blank?
section.active = true
section.save!

subsections = [
  { title: "ENEM",                slug: "enem",                 position: 1 },
  { title: "IDEB/SAEB",           slug: "ideb-saeb",            position: 2 },
  { title: "Avaliações Internas", slug: "avaliacoes-internas", position: 3 }
]

subsections.each do |attrs|
  subsection =
    SidebarSubsection.find_or_initialize_by(
      sidebar_section_id: section.id,
      slug: attrs[:slug]
    )

  subsection.title = attrs[:title]
  subsection.position = attrs[:position]
  subsection.active = true
  subsection.save!

  puts "OK: #{section.title} > #{subsection.title}"
end

puts
puts "Configuração concluída."
