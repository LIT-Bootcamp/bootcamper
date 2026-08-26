require "rails_helper"

RSpec.describe "Workshop map preview" do
  it "renders the ordered stations and their states" do
    get design_workshop_map_path

    expect(response).to have_http_status(:ok)
  end

  it "keeps stations in learning order" do
    get design_workshop_map_path

    expect(response.body.index("Основи")).to be < response.body.index("Інтернет")
  end

  it "shows every state label" do
    get design_workshop_map_path

    expect(response.body).to match(/Завершено.*Поточна.*Заблоковано/m)
  end

  it "does not require a signed-in user" do
    get design_workshop_map_path

    expect(response).not_to have_http_status(:redirect)
  end
end
