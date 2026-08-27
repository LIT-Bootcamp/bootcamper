require "rails_helper"

# rubocop:disable RSpecRails/InferredSpecType
RSpec.describe "Profile editing", type: :system do
  before { driven_by(:rack_test) }

  it "lets a student edit profile details", :aggregate_failures do
    user = sign_in_confirmed_user
    edit_profile

    expect(page).to have_content("Профіль збережено")
    expect(user.reload.display_name).to eq("Ada Lovelace")
  end

  private

  def sign_in_confirmed_user
    user = User.create!(email: "student@example.com", password: "correct horse battery", password_confirmation: "correct horse battery")
    user.confirm
    sign_in_user(user)
    user
  end

  def edit_profile
    visit account_path
    fill_in "Ім’я для відображення", with: "Ada Lovelace"
    fill_in "Технічні навички", with: "Ruby, SQL"
    click_button "Зберегти профіль"
  end

  def sign_in_user(user)
    visit login_path
    fill_in "Електронна пошта", with: user.email
    fill_in "Пароль", with: "correct horse battery"
    click_button "Увійти"
  end
end
# rubocop:enable RSpecRails/InferredSpecType
