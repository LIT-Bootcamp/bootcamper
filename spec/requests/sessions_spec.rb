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
    expect(response.body.downcase).to include("підтверд")
  end

  it "rejects a blocked user with the generic invalid-credentials response", :aggregate_failures do
    reject_blocked_login
    expect_generic_login_rejection
    expect_no_authenticated_session
  end

  it "rejects invalid credentials", :aggregate_failures do
    create_user.confirm

    submit_login(password: "wrong password")

    expect(response).to have_http_status(:unprocessable_content)
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
    create(:user, email: "student@example.com")
  end

  def reject_blocked_login
    user = create_user
    user.confirm
    user.update!(blocked: true)
    submit_login
    follow_redirect!
  end

  def expect_generic_login_rejection
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Електронна пошта або пароль")
  end

  def expect_no_authenticated_session
    get account_path
    expect(response).to redirect_to(login_path)
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
