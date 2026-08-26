require "rails_helper"

RSpec.describe "Home" do
  it "renders the Ukrainian landing page" do
    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "includes the Ukrainian introduction" do
    get root_path

    expect(response.body).to include("Навчальні подорожі")
  end
end
