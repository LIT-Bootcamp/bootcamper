require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "active_storage/engine"
require "rails/test_unit/railtie"
require "propshaft"
require "propshaft/railtie"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"

Bundler.require(*Rails.groups)

module Bootcamper
  class Application < Rails::Application
    config.load_defaults 8.1
    credentials_dir = Rails.root.join("config", "credentials")
    config.credentials.content_path = credentials_dir.join("#{Rails.env}.yml.enc")
    config.credentials.key_path = credentials_dir.join("#{Rails.env}.key")
    config.require_master_key = true
    config.i18n.default_locale = :uk
    config.time_zone = "Europe/Kyiv"
    config.generators.system_tests = nil
  end
end
