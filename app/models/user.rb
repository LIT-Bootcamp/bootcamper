class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable, :confirmable, :recoverable

  enum :role, { student: "student", admin: "admin" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def email_verified?
    confirmed?
  end
end
