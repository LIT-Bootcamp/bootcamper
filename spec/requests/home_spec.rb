require "rails_helper"

RSpec.describe "Home" do
  it "renders the Ukrainian landing page" do
    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "includes the Ukrainian introduction" do
    get root_path

    expect(response.body).to include("Практичний простір для вивчення веброзробки")
  end

  it "provides a skip link to the main content" do
    get root_path

    expect(response.body).to include('id="main-content"', "Перейти до основного вмісту")
  end

  it "renders the home destination in each responsive navigation" do
    get root_path

    expect(response.body.scan("Головна").length).to eq(2)
  end

  it "renders the remaining primary navigation destinations" do
    get root_path

    expect(response.body).to include("Майстерні", "Як це працює")
  end

  it "provides navigation landmarks for both responsive presentations" do
    get root_path

    expect(response.body.scan('aria-label="Основна навігація"').length).to eq(2)
  end
end
