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

  it "tests factory tooling separately from Rails coverage", :aggregate_failures do
    spec_helper = File.read(File.expand_path("../spec_helper.rb", __dir__))
    workflow = File.read(File.expand_path("../../.github/workflows/ci.yml", __dir__))

    expect(spec_helper).to include('skip "/lib/product_factory"')
    expect(workflow).to include("bundle exec rspec && env -u CI bin/product_factory test")
  end
end
