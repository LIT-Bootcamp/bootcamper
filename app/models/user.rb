class User < ApplicationRecord
  has_one_attached :avatar

  devise :database_authenticatable, :registerable, :validatable, :confirmable, :recoverable

  enum :role, { student: "student", admin: "admin" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :profile_urls_must_be_http_urls
  validate :github_url_must_be_http_url
  validate :avatar_must_be_an_image

  def email_verified?
    confirmed?
  end

  private

  def profile_urls_must_be_http_urls
    profile_urls.to_s.lines.map(&:strip).reject(&:blank?).each do |url|
      errors.add(:profile_urls, :invalid) unless http_url?(url)
    end
  end

  def github_url_must_be_http_url
    return if github_url.blank? || http_url?(github_url)

    errors.add(:github_url, :invalid)
  end

  def avatar_must_be_an_image
    return unless avatar.attached?

    detected_type = detected_avatar_content_type
    errors.add(:avatar, :invalid) unless detected_type.in?(%w[image/png image/jpeg image/webp])
    errors.add(:avatar, :too_large) if avatar.byte_size > 5.megabytes
  end

  def detected_avatar_content_type
    avatar.blob.open { |file| Marcel::MimeType.for(file, name: avatar.filename.to_s) }
  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    avatar.content_type
  end

  def http_url?(url)
    url.match?(%r{\Ahttps?://[^\s]+\z})
  end
end
