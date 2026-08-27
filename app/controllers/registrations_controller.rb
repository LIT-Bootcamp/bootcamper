class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :student
    @user.skip_confirmation_notification!

    if @user.save
      send_confirmation_instructions
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

  def send_confirmation_instructions
    @user.send_confirmation_instructions
  rescue ActionMailer::Error, Net::SMTPError, SocketError, SystemCallError => error
    Rails.logger.warn("Confirmation delivery unavailable (#{error.class})")
  end
end
