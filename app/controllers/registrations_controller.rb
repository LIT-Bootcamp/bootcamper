class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    result = Students::Register.result(attributes: user_params.to_h)
    @user = result.user

    return redirect_to(registration_success_path) if result.success? || result.acknowledged?

    render :new, status: :unprocessable_content
  end

  def success
  end

  private

  def user_params
    params.expect(user: [ :email, :password, :password_confirmation ])
  end
end
