require "rails_helper"

RSpec.describe "User sessions" do
  it "renders the localized sign-in form", :aggregate_failures do
    get login_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Увійти", "Електронна пошта", "Пароль")
  end

  it "signs in a confirmed user" do
    user = create_user
    user.confirm

    submit_login

    expect(response).to redirect_to(account_path)
  end

  it "rejects an unconfirmed user", :aggregate_failures do
    create_user

    submit_login
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("підтвердж")
  end

  it "rejects invalid credentials", :aggregate_failures do
    create_user.confirm

    submit_login(password: "wrong password")
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Електронна пошта або пароль")
  end

  it "ends a session with the delete logout action" do
    user = create_user
    user.confirm
    sign_in_user(user)

    delete logout_path, headers: csrf_headers

    expect(response).to redirect_to(root_path)
  end

  private

  def create_user
    User.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery")
  end

  def submit_login(password: "correct horse battery")
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]

    post login_path,
      params: { user: { email: "student@example.com", password: } },
      headers: { "X-CSRF-Token" => csrf_token }
  end

  def sign_in_user(user)
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    post login_path,
      params: { user: { email: user.email, password: "correct horse battery" } },
      headers: { "X-CSRF-Token" => csrf_token }
    follow_redirect!
  end

  def csrf_headers
    { "X-CSRF-Token" => response.body[/name="csrf-token" content="([^"]+)/, 1] }
  end
end
