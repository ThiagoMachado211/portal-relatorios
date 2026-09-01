puts "PEDAGÓGICO"
section = SidebarSection.find_by(slug: "setor-pedagogico")
puts "Seção: #{section&.id} | #{section&.title} | active=#{section&.active}"

if section
  section.sidebar_subsections.order(:position).each do |sub|
    puts "  - #{sub.id}: #{sub.title} | slug=#{sub.slug} | active=#{sub.active}"
  end
end

puts
puts "REPORT PAGES POR SUBSEÇÃO"
SidebarSubsection.where(slug: %w[enem ideb-saeb avaliacoes-internas]).each do |sub|
  puts "#{sub.title}: #{ReportPage.where(sidebar_subsection_id: sub.id).count} conteúdo(s)"
end
