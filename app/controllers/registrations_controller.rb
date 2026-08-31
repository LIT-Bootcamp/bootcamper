class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :student
    @user.skip_confirmation_notification!

    if @user.save
      enqueue_confirmation_work(@user)
      redirect_to registration_success_path
    elsif duplicate_email_only?
      enqueue_confirmation_work(existing_user_for(@user), send_confirmation: false)
      redirect_to registration_success_path
    else
      @user.errors.delete(:email, :taken)
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique => error
    raise unless duplicate_email_conflict?(error)

    enqueue_confirmation_work(existing_user_for(@user), send_confirmation: false)
    redirect_to registration_success_path
  end

  def success
  end

  private

  def user_params
    params.expect(user: [ :email, :password, :password_confirmation ])
  end

  def duplicate_email_only?
    @user.errors.of_kind?(:email, :taken) && @user.errors.attribute_names == [ :email ]
  end

  def duplicate_email_conflict?(error)
    error.cause&.message.to_s.include?("index_users_on_email")
  end

  def existing_user_for(user)
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
