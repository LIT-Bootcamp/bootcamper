# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  blocked                :boolean          default(FALSE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  display_name           :string
#  email                  :citext           not null
#  encrypted_password     :string           not null
#  github_url             :string
#  interests              :text
#  profile_urls           :text
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("student"), not null
#  technical_skills       :text
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "student#{number}@example.com" }
    password { "correct horse battery" }
    password_confirmation { password }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :admin do
      role { :admin }
    end

    trait :with_profile do
      display_name { "Ada Lovelace" }
      technical_skills { "Ruby\nSQL" }
      interests { "Learning design" }
      github_url { "https://github.com/ada" }
      profile_urls { "https://example.com/ada\nhttps://linkedin.com/in/ada" }
    end
  end
end
