require "rails_helper"

RSpec.describe User do
  let(:valid_attributes) do
    { email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery" }
  end
  let(:encrypted_password) { described_class.new(valid_attributes).encrypted_password }

  describe "role" do
    it "defaults to student" do
      expect(described_class.new(valid_attributes).role).to eq("student")
    end

    it "accepts student" do
      expect(described_class.new(valid_attributes.merge(role: :student))).to be_valid
    end

    it "accepts admin" do
      expect(described_class.new(valid_attributes.merge(role: :admin))).to be_valid
    end

    it "rejects an unsupported role" do
      user = described_class.new(valid_attributes.merge(role: "moderator"))

      expect(user).not_to be_valid
    end

    it "cannot persist an unsupported role" do
      expect {
        described_class.insert_all!([ { email: "invalid-role@example.com", role: "moderator", encrypted_password: } ])
      }.to raise_error(ActiveRecord::StatementInvalid, /users_role_check/)
    end
  end

  describe "email" do
    it "normalizes surrounding whitespace and case" do
      user = described_class.new(email: "  Student@Example.COM ")

      expect(user.email).to eq("student@example.com")
    end

    it "requires a unique value regardless of case" do
      described_class.create!(valid_attributes)
      duplicate = described_class.new(valid_attributes.merge(email: "STUDENT@EXAMPLE.COM"))

      expect(duplicate).not_to be_valid
    end
  end

  describe "password" do
    it "validates and stores a secure password", :aggregate_failures do
      user = described_class.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery")

      expect(user.encrypted_password).to be_present
      expect(user.encrypted_password).not_to include("correct horse battery")
      expect(user).to be_valid_password("correct horse battery")
    end
  end
end
