require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "propshaft/railtie"
# require "action_cable/engine"

Bundler.require(*Rails.groups)

module PortalRelatorios
  class Application < Rails::Application
    config.load_defaults 8.0
  end
end