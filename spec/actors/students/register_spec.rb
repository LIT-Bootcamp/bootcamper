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
end
