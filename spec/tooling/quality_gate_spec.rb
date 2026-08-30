require "spec_helper"

RSpec.describe "Local quality gate" do # rubocop:disable RSpec/DescribeClass
  let(:pre_push) { File.read(File.expand_path("../../.githooks/pre-push", __dir__)) }

  it "runs droast as part of quality" do
    quality = File.read(File.expand_path("../../bin/quality", __dir__))

    expect(quality).to include("droast --no-roast --fail-on warning .")
  end

  it "pins droast in the development image" do
    dockerfile = File.read(File.expand_path("../../Dockerfile", __dir__))

    expect(dockerfile).to include("FROM immanuwell/droast:1.6.1 AS droast")
  end

  it "prepares the test database before push" do
    expect(pre_push).to include("RAILS_ENV=test bin/rails db:prepare")
  end

  it "runs quality before push" do
    expect(pre_push).to include("RAILS_ENV=test bin/quality")
  end

  it "runs tests before push" do
    expect(pre_push).to include("RAILS_ENV=test bundle exec rspec")
  end
end
