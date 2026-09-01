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

  it "confirms an account with a single-use link" do
    user = create_unconfirmed_user
    token = confirmation_token_from_last_email

    expect { get confirmation_path, params: { confirmation_token: token } }
      .to change { user.reload.email_verified? }.from(false).to(true)
  end

  it "confirms a blocked account without clearing its blocked state", :aggregate_failures do
    user = blocked_unconfirmed_user
    get confirmation_path, params: { confirmation_token: confirmation_token_from_last_email }
    expect_blocked_user_confirmed(user)
  end

  it "rejects a confirmation link after it is used" do
    create_unconfirmed_user
    token = confirmation_token_from_last_email
    get confirmation_path, params: { confirmation_token: token }

    get confirmation_path, params: { confirmation_token: token }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects an expired confirmation link" do
    user = create_unconfirmed_user
    user.update!(confirmation_sent_at: 4.days.ago)

    get confirmation_path, params: { confirmation_token: confirmation_token_from_last_email }

    expect(response).to have_http_status(:unprocessable_content)
  end

  private

  def create_unconfirmed_user
    create(:user, email: "student@example.com")
  end

  def blocked_unconfirmed_user
    create_unconfirmed_user.tap { |user| user.update!(blocked: true) }
  end

  def expect_blocked_user_confirmed(user)
    expect(response).to redirect_to(confirmation_success_path)
    expect(user.reload).to be_email_verified
    expect(user).to be_blocked
  end

  def confirmation_token_from_last_email
    ActionMailer::Base.deliveries.last.body.to_s[/confirmation_token=([^&"]+)/, 1]
  end
end
