require "rails_helper"

RSpec.describe RegistrationConfirmationJob do
  before { ActionMailer::Base.deliveries.clear }

  it "does not look up a user when confirmation delivery is disabled" do
    expect(described_class.perform_now(-1, send_confirmation: false)).to be_nil
  end

  it "sends confirmation instructions to an unconfirmed user" do
    user = build_unconfirmed_user

    described_class.perform_now(user.id)

    expect(ActionMailer::Base.deliveries.last).to have_attributes(to: [ user.email ])
  end

  it "does not send confirmation instructions to a confirmed user" do
    user = create(:user, :confirmed)

    described_class.perform_now(user.id)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  private

  def build_unconfirmed_user
    build(:user).tap do |user|
      user.skip_confirmation_notification!
      user.save!
    end
  end
end
