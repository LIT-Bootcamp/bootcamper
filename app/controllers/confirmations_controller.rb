class ConfirmationsController < ApplicationController
  def show
    result = Confirmations::Confirm.result(confirmation_token: params.expect(:confirmation_token))
    @user = result.user

    if result.success?
      flash[:confirmation_success_variant] = result.success_variant
      redirect_to confirmation_success_path
    else
      render :invalid, status: :unprocessable_content
    end
  end

  def success
    @presenter = ConfirmationSuccessPresenter.new(success_variant: flash[:confirmation_success_variant])
  end
end
