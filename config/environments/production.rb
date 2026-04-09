Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false
  config.public_file_server.enabled = true
  config.active_storage.resolve_model_to_route = :rails_storage_proxy

  config.assets.compile = false

  config.active_storage.service = :local
end