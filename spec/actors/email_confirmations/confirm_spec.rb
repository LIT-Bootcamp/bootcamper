require "rails_helper"

RSpec.describe EmailConfirmations::Confirm do
  before { ActionMailer::Base.deliveries.clear }

  it "returns a sign-in-ready variant for an active account", :aggregate_failures do
    create(:user, email: "student@example.com")

    result = described_class.result(confirmation_token: current_confirmation_token)

    expect(result).to be_success
    expect(result.user.reload).to be_email_verified
    expect(result.success_variant).to eq(:success_message_sign_in_available)
  end

  it "returns a blocked variant for a blocked account", :aggregate_failures do
    create(:user, email: "student@example.com", blocked: true)

    result = described_class.result(confirmation_token: current_confirmation_token)

    expect(result).to be_success
    expect(result.user.reload).to be_email_verified
    expect(result.success_variant).to eq(:success_message_still_blocked)
  end

  it "fails with the confirmation errors for an invalid token" do
    result = described_class.result(confirmation_token: "not-a-real-token")

    expect(result).to have_attributes(success?: false, user: have_attributes(errors: be_present))
  end

  private

  def current_confirmation_token
    ActionMailer::Base.deliveries.last.body.to_s[/confirmation_token=([^&"]+)/, 1]
  end
end
