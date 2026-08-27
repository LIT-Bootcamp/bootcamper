class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    return if current_user&.admin?

    render plain: I18n.t("admin.access_denied"), status: :forbidden
  end
end
