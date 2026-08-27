require "rails_helper"

RSpec.describe "Password recovery" do
  before { ActionMailer::Base.deliveries.clear }

  it "renders the localized password reset request form", :aggregate_failures do
    get new_password_reset_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Відновити пароль", "Електронна пошта")
  end

  it "returns the same response for known and unknown addresses" do
    create_user
    known_response = request_reset_for("student@example.com")
    ActionMailer::Base.deliveries.clear
    unknown_response = request_reset_for("unknown@example.com")

    expect(known_response).to eq(unknown_response)
  end

  it "sends one reset link for a known address", :aggregate_failures do
    create_user

    request_reset_for("student@example.com")

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.last.body.to_s).to include("/password/reset/edit?reset_password_token=")
  end

  it "keeps the generic response when reset delivery fails", :aggregate_failures do
    user = create_user
    allow(UserMailer).to receive(:reset_password_instructions).and_raise(ActionMailer::Error, "delivery unavailable")

    response_body = request_reset_for(user.email)

    expect(response_body).to include("Якщо обліковий запис із цією адресою існує")
    expect(User.exists?(user.id)).to be(true)
  end

  it "keeps the generic response when reset delivery times out", :aggregate_failures do
    user = create_user
    allow(UserMailer).to receive(:reset_password_instructions).and_raise(Timeout::Error, "delivery timed out")

    response_body = request_reset_for(user.email)

    expect(response_body).to include("Якщо обліковий запис із цією адресою існує")
    expect(User.exists?(user.id)).to be(true)
  end

  it "accepts a valid token without signing the user in", :aggregate_failures do
    user = create_reset_user
    apply_reset(reset_token_from_last_email)

    expect(response).to redirect_to(login_path)
    expect(request.session.keys).not_to include("warden.user.user.key")
    expect(user.reload).to be_valid_password("new horse battery")
  end

  it "rejects an expired token" do
    user = create_user
    request_reset_for(user.email)
    user.update!(reset_password_sent_at: 7.hours.ago)

    get edit_password_reset_path, params: { reset_password_token: reset_token_from_last_email }

    expect(response).to redirect_to(login_path)
  end

  it "rejects an unknown token" do
    get edit_password_reset_path, params: { reset_password_token: "unknown-token" }

    expect(response).to redirect_to(login_path)
  end

  it "rejects a token after it has been consumed", :aggregate_failures do
    user = create_reset_user
    apply_reset_twice(reset_token_from_last_email)

    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload).to be_valid_password("new horse battery")
  end

  private

  def create_user
    User.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery")
  end

  def create_reset_user
    create_user.tap { |user| request_reset_for(user.email) }
  end

  def apply_reset(token)
    patch password_reset_path,
      params: { user: { reset_password_token: token, password: "new horse battery", password_confirmation: "new horse battery" } }
  end

  def apply_reset_twice(token)
    2.times { apply_reset(token) }
  end

  def request_reset_for(email)
    post password_reset_path, params: { user: { email: } }
    follow_redirect!
    response.body
  end

  def reset_token_from_last_email
    ActionMailer::Base.deliveries.last.body.to_s[/reset_password_token=([^&"]+)/, 1]
  end
end
