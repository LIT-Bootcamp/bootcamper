# frozen_string_literal: true

module EmailConfirmations
  class Confirm < Actor
    input :confirmation_token, type: String

    output :user
    output :success_variant

    def call
      self.user = find_user
      return confirm_unknown_user unless user

      user.with_lock do
        user.reload
        fail_with_invalid_proof unless current_confirmation_proof?

        user.confirm
        fail!(user:) if user.errors.any?
      end

      self.success_variant = confirmation_success_variant_for(user)
    end

    private

    def find_user
      User.find_by(confirmation_token:) || User.find_by(confirmation_token: confirmation_digest)
    end

    def confirmation_digest
      Devise.token_generator.digest(User, :confirmation_token, confirmation_token)
    end

    def current_confirmation_proof?
      user.confirmation_token == confirmation_token || user.confirmation_token == confirmation_digest
    end

    def confirm_unknown_user
      self.user = User.confirm_by_token(confirmation_token)
      fail!(user:)
    end

    def fail_with_invalid_proof
      user.errors.add(:confirmation_token, :invalid)
      fail!(user:)
    end

    def confirmation_success_variant_for(user)
      user.active_for_authentication? ? :success_message_sign_in_available : :success_message_still_blocked
    end
  end
end
