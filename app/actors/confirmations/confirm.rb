# frozen_string_literal: true

module Confirmations
  class Confirm < Actor
    input :confirmation_token, type: String

    output :user
    output :success_variant

    def call
      self.user = User.confirm_by_token(confirmation_token)
      fail!(user:) if user.errors.any?

      self.success_variant = confirmation_success_variant_for(user)
    end

    private

    def confirmation_success_variant_for(user)
      user.active_for_authentication? ? :success_message_sign_in_available : :success_message_still_blocked
    end
  end
end
