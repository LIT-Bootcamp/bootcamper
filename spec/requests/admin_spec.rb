require "rails_helper"

RSpec.describe "Admin workspace" do
  it "redirects anonymous visitors to sign in" do
    get "/admin"

    expect(response).to redirect_to(login_path)
  end

  it "forbids students" do
    sign_in_user(create_user(role: :student))

    get "/admin"

    expect(response).to have_http_status(:forbidden)
  end

  it "renders an empty overview for admins", :aggregate_failures do
    sign_in_user(create_user(role: :admin))

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Адмін-простір", "Поки що тут порожньо")
  end

  private

  def create_user(role:)
    create(:user, :confirmed, role:)
  end

  def sign_in_user(user)
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    post login_path,
      params: { user: { email: user.email, password: "correct horse battery" } },
      headers: { "X-CSRF-Token" => csrf_token }
    follow_redirect!
  end
end
