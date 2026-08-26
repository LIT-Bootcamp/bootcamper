require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.force_ssl = true
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL") { "info" }
  config.active_storage.service = :local
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
end
