require "rails_helper"

RSpec.describe User do
  describe "role" do
    it "defaults to student" do
      expect(described_class.new.role).to eq("student")
    end

    it "accepts student" do
      expect(described_class.new(role: :student)).to be_valid
    end

    it "accepts admin" do
      expect(described_class.new(role: :admin)).to be_valid
    end

    it "rejects an unsupported role" do
      user = described_class.new(role: "moderator")

      expect(user).not_to be_valid
    end

    it "cannot persist an unsupported role" do
      expect {
        described_class.insert_all!([ { email: "invalid-role@example.com", role: "moderator" } ])
      }.to raise_error(ActiveRecord::StatementInvalid, /users_role_check/)
    end
  end

  describe "email" do
    it "normalizes surrounding whitespace and case" do
      user = described_class.new(email: "  Student@Example.COM ")

      expect(user.email).to eq("student@example.com")
    end

    it "requires a unique value regardless of case" do
      described_class.create!(email: "student@example.com")
      duplicate = described_class.new(email: "STUDENT@EXAMPLE.COM")

      expect(duplicate).not_to be_valid
    end
  end
end
