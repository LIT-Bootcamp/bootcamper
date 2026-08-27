require "rails_helper"

RSpec.describe "Student registration" do
  before { ActionMailer::Base.deliveries.clear }

  it "renders the Ukrainian registration form", :aggregate_failures do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Створити обліковий запис", "Електронна пошта")
  end

  it "creates a student and does not sign them in", :aggregate_failures do
    submit_registration

    expect(response).to redirect_to(registration_success_path)
    expect(User.find_by(email: "student@example.com")).to have_attributes(role: "student", encrypted_password: a_string_matching(/\A\$2/))
    expect(request.session.keys).not_to include("warden.user.user.key")
  end

  it "sends one confirmation link after account creation", :aggregate_failures do
    submit_registration

    confirmation_email = ActionMailer::Base.deliveries.last
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(confirmation_email.to).to eq([ "student@example.com" ])
    expect(confirmation_email.body.to_s).to include("/register/confirm?confirmation_token=")
  end

  it "shows a truthful account-created state" do
    submit_registration
    follow_redirect!

    expect(response.body).to include("Твій обліковий запис створено")
  end

  it "renders localized validation errors for invalid input", :aggregate_failures do
    submit_registration(email: "not-an-email", password: "short", password_confirmation: "different")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("має некоректний формат", "занадто короткий", "не збігається")
  end

  it "renders a localized duplicate email error", :aggregate_failures do
    User.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery")

    submit_registration(email: "STUDENT@example.com")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("вже використовується")
  end

  private

  def submit_registration(email: "student@example.com", password: "correct horse battery", password_confirmation: password)
    get new_user_registration_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]

    post user_registration_path,
      params: { user: { email:, password:, password_confirmation: } },
      headers: { "X-CSRF-Token" => csrf_token }
  end
end
