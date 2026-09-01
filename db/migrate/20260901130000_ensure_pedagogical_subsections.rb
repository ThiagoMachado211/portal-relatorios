class EnsurePedagogicalSubsections < ActiveRecord::Migration[8.1]
  class MigrationSidebarSection < ActiveRecord::Base
    self.table_name = "sidebar_sections"
  end

  class MigrationSidebarSubsection < ActiveRecord::Base
    self.table_name = "sidebar_subsections"
  end

  def up
    section = MigrationSidebarSection.find_or_initialize_by(slug: "setor-pedagogico")
    section.title = "Pedagógico" if section.respond_to?(:title=)
    section.active = true if section.respond_to?(:active=)
    section.position ||= 2 if section.respond_to?(:position)
    section.save!

    [
      ["ENEM", "enem", 1],
      ["IDEB/SAEB", "ideb-saeb", 2],
      ["Avaliações Internas", "avaliacoes-internas", 3]
    ].each do |title, slug, position|
      subsection = MigrationSidebarSubsection.find_or_initialize_by(
        sidebar_section_id: section.id,
        slug: slug
      )

      subsection.title = title if subsection.respond_to?(:title=)
      subsection.active = true if subsection.respond_to?(:active=)
      subsection.position = position if subsection.respond_to?(:position=)
      subsection.save!
    end
  end

  def down
  end
end
