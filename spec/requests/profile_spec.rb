require "rails_helper"

RSpec.describe "Student profile" do
  it "updates the authenticated user's profile", :aggregate_failures do
    user = sign_in_confirmed_user
    patch_profile(display_name: "Ada Lovelace", technical_skills: "Ruby\nSQL")

    expect(response).to redirect_to(account_path)
    expect(user.reload).to have_attributes(display_name: "Ada Lovelace", technical_skills: "Ruby\nSQL")
  end

  it "renders localized errors for an invalid profile URL", :aggregate_failures do
    sign_in_confirmed_user
    patch_profile(github_url: "javascript:alert(1)")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("має некоректний формат")
  end

  it "requires authentication to update a profile" do
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    patch account_path, params: { user: { display_name: "Intruder" } }, headers: { "X-CSRF-Token" => csrf_token }

    expect(response).to redirect_to(login_path)
  end

  private

  def sign_in_confirmed_user
    create_confirmed_user.tap { |user| sign_in_user(user) }
  end

  def create_confirmed_user
    User.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery").tap(&:confirm)
  end

  def sign_in_user(user)
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    post login_path,
      params: { user: { email: user.email, password: "correct horse battery" } },
      headers: { "X-CSRF-Token" => csrf_token }
    follow_redirect!
  end

  def patch_profile(attributes)
    get account_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    patch account_path, params: { user: attributes }, headers: { "X-CSRF-Token" => csrf_token }
  end
end
