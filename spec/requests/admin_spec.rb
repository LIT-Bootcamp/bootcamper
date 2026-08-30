require "rails_helper"

RSpec.describe "Admin workspace" do
  include_context "with authenticated request"

  it "redirects anonymous visitors to sign in" do
    get "/admin"

    expect(response).to redirect_to(login_path)
  end

  it "forbids students" do
    sign_in_as(create(:user, :confirmed))

    get "/admin"

    expect(response).to have_http_status(:forbidden)
  end

  it "renders an empty overview for admins", :aggregate_failures do
    sign_in_as(create(:user, :admin, :confirmed))

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Адмін-простір", "Поки що тут порожньо")
  end
end
