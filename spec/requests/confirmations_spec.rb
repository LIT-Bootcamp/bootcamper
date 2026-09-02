require "rails_helper"

RSpec.describe "Email confirmation" do
  before { ActionMailer::Base.deliveries.clear }

  it "requires an explicit production host for confirmation URLs" do
    production_config = Rails.root.join("config/environments/production.rb").read

    expect(production_config).to include('ENV.fetch("APP_HOST")')
      .and include('protocol: "https"')
  end

  it "generates confirmation URLs from configured mailer defaults" do
    url = UserMailer.new.confirmation_url(User.new, confirmation_token: "token")

    expect(url).to start_with("http://www.example.com/register/confirm")
      .and include("confirmation_token=token")
  end

  it "confirms an account with the current single-use link", :aggregate_failures do
    user = create_unconfirmed_user

    expect { confirm_with(current_confirmation_token) }
      .to change { user.reload.email_verified? }.from(false).to(true)

    expect_sign_in_ready_confirmation(user)
  end

  it "confirms a blocked account without clearing its blocked state", :aggregate_failures do
    user = blocked_unconfirmed_user

    confirm_with(current_confirmation_token)

    expect_blocked_user_confirmed(user)
    expect_blocked_confirmation_message
    expect_blocked_user_login_rejected(user)
  end

  it "rejects an unknown confirmation link without changing account state", :aggregate_failures do
    user = create_unconfirmed_user

    expect_invalid_confirmation_attempt("not-a-real-token", user)
  end

  it "rejects a confirmation request without a token without changing account state", :aggregate_failures do
    user = create_unconfirmed_user

    expect_invalid_confirmation_attempt(:missing, user)
  end

  it "rejects a blank confirmation token without changing account state", :aggregate_failures do
    user = create_unconfirmed_user

    expect_invalid_confirmation_attempt("", user)
  end

  it "rejects an array confirmation token without changing account state", :aggregate_failures do
    user = create_unconfirmed_user

    expect_invalid_confirmation_attempt([ "not-a-real-token" ], user)
  end

  it "rejects a confirmation link after it is used without changing account state", :aggregate_failures do
    create_unconfirmed_user
    token = current_confirmation_token
    state_after_confirmation = confirm_and_capture_state(token)

    expect_reused_confirmation_to_fail(token, state_after_confirmation)
  end

  it "rejects an expired confirmation link without changing account state", :aggregate_failures do
    user = create_unconfirmed_user
    user.update!(confirmation_sent_at: 4.days.ago)

    expect_invalid_confirmation_attempt(current_confirmation_token, user)
  end

  it "rejects a superseded confirmation link without changing account state", :aggregate_failures do
    user = create_unconfirmed_user
    superseded_token = current_confirmation_token
    current_token = issue_new_confirmation_proof_for(user)

    expect(current_token).not_to eq(superseded_token)

    expect_invalid_confirmation_attempt(superseded_token, user)
  end

  private

  def create_unconfirmed_user
    create(:user, email: "student@example.com")
  end

  def blocked_unconfirmed_user
    create_unconfirmed_user.tap { |user| user.update!(blocked: true) }
  end

  def expect_blocked_user_confirmed(user)
    expect(user.reload).to be_email_verified
    expect(user).to be_blocked
  end

  def expect_successful_confirmation(user, message)
    expect(user.reload.confirmed_at).to be_present
    expect(response.body).to include(message)
  end

  def expect_sign_in_ready_confirmation(user)
    expect_successful_confirmation(
      user,
      "Тепер можна увійти за електронною поштою та паролем."
    )
  end

  def expect_blocked_confirmation_message
    expect(response.body).to include("Вхід для цього облікового запису поки недоступний.")
    expect(response.body).not_to include("Тепер можна увійти за електронною поштою та паролем.")
  end

  def expect_blocked_user_login_rejected(user)
    submit_login_for(user)
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Електронна пошта або пароль")

    get account_path
    expect(response).to redirect_to(login_path)
  end

  def expect_invalid_confirmation_attempt(token, user)
    state_before_attempt = confirmation_state_for(user.reload)

    confirm_with(token)

    expect_invalid_confirmation_response
    expect(confirmation_state_for(user.reload)).to eq(state_before_attempt)
  end

  def confirm_and_capture_state(token)
    confirm_with(token)
    confirmation_state_for(User.last.reload)
  end

  def expect_reused_confirmation_to_fail(token, state_after_confirmation)
    confirm_with(token)

    expect_invalid_confirmation_response
    expect(confirmation_state_for(User.last.reload)).to eq(state_after_confirmation)
  end

  def expect_invalid_confirmation_response
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(
      I18n.t("confirmation.invalid_title"),
      I18n.t("confirmation.invalid_message")
    )
  end

  def confirmation_state_for(user)
    user.attributes.slice(
      "blocked",
      "confirmation_sent_at",
      "confirmation_token",
      "confirmed_at",
      "email",
      "unconfirmed_email"
    )
  end

  def issue_new_confirmation_proof_for(user)
    user.update_columns(
      confirmation_token: nil,
      confirmation_sent_at: nil,
      updated_at: Time.current
    )
    user.class.find(user.id).send_confirmation_instructions

    current_confirmation_token
  end

  def current_confirmation_token
    ActionMailer::Base.deliveries.last.body.to_s[/confirmation_token=([^&"]+)/, 1]
  end

  def confirm_with(token)
    request_params = token == :missing ? {} : { confirmation_token: token }
    get confirmation_path, params: request_params
    follow_redirect! if response.redirect?
  end

  def submit_login_for(user, password: "correct horse battery")
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]

    post login_path,
      params: { user: { email: user.email, password: } },
      headers: { "X-CSRF-Token" => csrf_token }
  end
end
