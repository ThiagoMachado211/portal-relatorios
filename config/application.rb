require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module PortalRelatorios
  class Application < Rails::Application
    config.load_defaults 8.0

    # Timezone
    config.time_zone = "America/Sao_Paulo"

    # Evita erro com propshaft
    config.assets.enabled = true

    # Active Storage
    config.active_storage.variant_processor = :vips

    # Autoload
    config.autoload_lib(ignore: %w[assets tasks])
  end
end