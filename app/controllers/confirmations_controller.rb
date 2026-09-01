class ConfirmationsController < ApplicationController
  def show
    @user = User.confirm_by_token(params.expect(:confirmation_token))

    if @user.errors.empty?
      flash[:confirmation_success_variant] = confirmation_success_variant_for(@user)
      redirect_to confirmation_success_path
    else
      render :invalid, status: :unprocessable_content
    end
  end

  def success
    @success_message_key = "confirmation.#{flash[:confirmation_success_variant] || :success_message}"
  end

  private

  def confirmation_success_variant_for(user)
    user.active_for_authentication? ? :success_message_sign_in_available : :success_message_still_blocked
  end
end
