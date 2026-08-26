class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :student

    if @user.save
      redirect_to registration_success_path
    else
      render :new, status: :unprocessable_content
    end
  end

  def success
  end

  private

  def user_params
    params.expect(user: [ :email, :password, :password_confirmation ])
  end
end
