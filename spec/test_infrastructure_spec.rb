require "rails_helper"

RSpec.describe "test infrastructure" do # rubocop:disable RSpec/DescribeClass
  it "builds valid users with reusable traits", :aggregate_failures do
    expect(build(:user)).to be_valid
    expect(build(:user, :admin)).to be_admin
    expect(create(:user, :confirmed)).to be_confirmed
  end

  it "loads matcher and coverage integrations", :aggregate_failures do
    expect(Shoulda::Matchers).to be_a(Module)
    expect(Coverage.running?).to be(true)
  end
end # rubocop:enable RSpec/DescribeClass
