require "rails_helper"

RSpec.describe "Account access" do
  it "returns an anonymous visitor to the protected page after sign-in", :aggregate_failures do
    request_account_as_anonymous
    submit_login(create_confirmed_user)

    expect(response).to redirect_to(account_path)
  end

  it "renders the authenticated account page", :aggregate_failures do
    render_authenticated_account

    expect(response).to have_http_status(:ok)
    expect_account_navigation
  end

  private

  def create_confirmed_user
    create(:user, :confirmed)
  end

  def request_account_as_anonymous
    get account_path

    expect(response).to redirect_to(login_path)
    follow_redirect!
  end

  def submit_login(user)
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    post login_path,
      params: { user: { email: user.email, password: "correct horse battery" } },
      headers: { "X-CSRF-Token" => csrf_token }
  end

  def render_authenticated_account
    submit_login(create_confirmed_user)
    follow_redirect!
    get account_path
  end

  def expect_account_navigation
    expect(response.body).to include("Твій обліковий запис")
    expect(response.body).to include("href=\"/account\"")
    expect(response.body).not_to include("href=\"/tasks\"", "href=\"/team\"", "href=\"/calendar\"", "href=\"/profile\"")
  end
end
