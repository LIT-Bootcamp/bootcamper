require "rails_helper"

RSpec.describe RegistrationsController do
  include Devise::Test::ControllerHelpers

  render_views

  before { ActionMailer::Base.deliveries.clear }

  it "renders the Ukrainian registration form", :aggregate_failures do
    get :new

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Створити обліковий запис", "Електронна пошта")
  end

  it "creates a student and does not sign them in", :aggregate_failures do
    expect { submit_registration }.to change(User, :count).by(1)

    expect(response).to redirect_to(registration_success_path)
    expect(User.find_by(email: "student@example.com")).to have_attributes(role: "student", encrypted_password: a_string_matching(/\A\$2/))
    expect(request.session.keys).not_to include("warden.user.user.key")
  end

  it "shows a truthful account-created state" do
    submit_registration
    get :success

    expect(response.body).to include("Твій обліковий запис створено")
  end

  it "renders localized validation errors for invalid input", :aggregate_failures do
    submit_registration(email: "not-an-email", password: "short", password_confirmation: "different")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("має некоректний формат", "занадто короткий", "не збігається")
  end

  it "returns the same visible acknowledgement for a duplicate email" do
    create_existing_user

    expect_duplicate_registration_acknowledgement
  end

  it "keeps password errors actionable without disclosing a duplicate email" do
    create_existing_user
    submit_registration(email: "student@example.com", password: "short", password_confirmation: "different")

    expect_duplicate_email_to_remain_hidden
    expect_password_errors_to_be_actionable
  end

  private

  def create_existing_user
    create(:user, :confirmed, email: "student@example.com")
  end

  def expect_duplicate_registration_acknowledgement
    expect { submit_registration(email: "STUDENT@example.com") }.not_to change(User, :count)
    expect(response).to redirect_to(registration_success_path)

    get :success

    expect(response.body).to include("Твій обліковий запис створено", "Перевір електронну пошту")
    expect(response.body).not_to include("вже використовується")
  end

  def expect_duplicate_email_to_remain_hidden
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).not_to include("вже використовується")
  end

  def expect_password_errors_to_be_actionable
    expect(response.body).to include("занадто короткий", "не збігається")
  end

  def submit_registration(email: "student@example.com", password: "correct horse battery", password_confirmation: password)
    post :create,
      params: { user: { email:, password:, password_confirmation: } }
  end
end
