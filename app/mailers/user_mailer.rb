class UserMailer < Devise::Mailer
  def confirmation_url(_resource, options = {})
    route_options = Rails.application.config.action_mailer.default_url_options.merge(options)
    Rails.application.routes.url_helpers.confirmation_url(**route_options)
  end

  def reset_password_url(_resource, options = {})
    route_options = Rails.application.config.action_mailer.default_url_options.merge(options)
    Rails.application.routes.url_helpers.edit_password_reset_url(**route_options)
  end
end
