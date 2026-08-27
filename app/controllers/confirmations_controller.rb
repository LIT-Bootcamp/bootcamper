class ConfirmationsController < ApplicationController
  def show
    @user = User.confirm_by_token(params.expect(:confirmation_token))

    if @user.errors.empty?
      redirect_to confirmation_success_path
    else
      render :invalid, status: :unprocessable_content
    end
  end

  def success
  end
end
