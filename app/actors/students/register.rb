# frozen_string_literal: true

module Students
  class Register < Actor
    input :attributes, type: Hash

    output :user
    output :acknowledged

    def call
      self.user = User.new(attributes)
      user.role = :student
      user.skip_confirmation_notification!

      return enqueue_confirmation_work(user) if user.save

      handle_failed_registration
    end

    private

    def handle_failed_registration
      if duplicate_email_only?
        enqueue_confirmation_work(existing_user, send_confirmation: false)
        self.acknowledged = true
      else
        user.errors.delete(:email, :taken)
        fail!(user:)
      end
    end

    def duplicate_email_only?
      user.errors.of_kind?(:email, :taken) && user.errors.attribute_names == [ :email ]
    end

    def existing_user
      return if user.email.blank?

      User.find_by(email: user.email)
    end

    def enqueue_confirmation_work(user, send_confirmation: true)
      return unless user

      RegistrationConfirmationJob.perform_later(user.id, send_confirmation:)
    rescue ActiveJob::EnqueueError => error
      Rails.logger.warn("Confirmation delivery unavailable (#{error.class})")
    end
  end
end
