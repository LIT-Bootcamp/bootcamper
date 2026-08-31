class RegistrationConfirmationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true

  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, send_confirmation: true)
    return unless send_confirmation

    user = User.find(user_id)
    return if user.confirmed?

    user.send_confirmation_instructions
  rescue ActionMailer::Error, Net::SMTPError, SocketError, SystemCallError => error
    Rails.logger.warn("Confirmation delivery unavailable (#{error.class})")
  end
end
