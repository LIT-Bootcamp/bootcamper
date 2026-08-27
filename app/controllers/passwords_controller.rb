class PasswordsController < Devise::PasswordsController
  def create
    super
  rescue ActionMailer::Error, Net::SMTPError, SocketError, SystemCallError, Timeout::Error => error
    Rails.logger.warn("Password reset delivery unavailable (#{error.class})")
    redirect_to new_password_reset_path, notice: I18n.t("devise.passwords.send_paranoid_instructions")
  end

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_password_reset_path
  end

  def after_resetting_password_path_for(_resource)
    login_path
  end

  def assert_reset_token_passed
    if params[:reset_password_token].present?
      resource = resource_class.with_reset_password_token(params[:reset_password_token])
      return if resource&.reset_password_period_valid?
    end

    set_flash_message(:alert, :no_token)
    redirect_to login_path
  end
end
