class User < ApplicationRecord
  enum :role, { student: "student", admin: "admin" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
