require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LoginWithDropbox
  class Application < Rails::Application
    config.active_record.raise_in_transactional_callbacks = true
    config.action_mailer.smtp_settings = {
      address: "smtp.gmail.com",
      port: 587,
      domain: "jshawl.com",
      user_name: ENV['gmail_username'],
      password: ENV['gmail_password'],
      authentication: :plain,
      enable_starttls_auto: true
    }
    config.action_mailer.default_url_options = {
        host: "updog.co"
    }
    config.autoload_paths += %W(#{config.root}/lib)
  end
end
