require "rails_helper"

RSpec.describe Students::Register do
  let(:result) { described_class.result(attributes:) }
  let(:attributes) do
    {
      email: "student@example.com",
      password: "correct horse battery",
      password_confirmation: "correct horse battery"
    }
  end

  it "creates an inactive student", :aggregate_failures do
    expect(result).to be_success
    expect(result.user).to have_attributes(role: "student", confirmed_at: nil)
  end

  it "keeps registration successful when confirmation work cannot be enqueued", :aggregate_failures do
    allow(RegistrationConfirmationJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, "queue unavailable")
    allow(Rails.logger).to receive(:warn)

    expect(result).to be_success
    expect(Rails.logger).to have_received(:warn).with("Confirmation delivery unavailable (ActiveJob::EnqueueError)")
  end
end
