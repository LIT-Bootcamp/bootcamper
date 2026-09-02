# frozen_string_literal: true

class EmailConfirmationsController < ApplicationController
  def show
    token = params[:confirmation_token]
    return render_invalid_confirmation unless token.is_a?(String) && token.present?

    result = EmailConfirmations::Confirm.result(confirmation_token: token)
    @user = result.user

    if result.success?
      flash[:confirmation_success_variant] = result.success_variant
      redirect_to confirmation_success_path
    else
      render_invalid_confirmation
    end
  end

  def success
    @presenter = ConfirmationSuccessPresenter.new(success_variant: flash[:confirmation_success_variant])
    render "confirmations/success"
  end

  private

  def render_invalid_confirmation
    render "confirmations/invalid", status: :unprocessable_content
  end
end
