class AccountController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to account_path, notice: t("account.updated")
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.expect(user: [ :display_name, :avatar, :technical_skills, :interests, :github_url, :profile_urls ])
  end
end
