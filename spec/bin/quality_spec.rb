require "open3"

RSpec.describe "bin/quality" do # rubocop:disable RSpec/DescribeClass
  let(:check_commands) do
    [
      "bundle exec brakeman --no-pager --exit-on-warn",
      "bundle exec bundler-audit check --update",
      "bundle exec database_consistency",
      "bundle exec annotaterb models --frozen"
    ]
  end

  def list(group)
    Open3.capture3("ruby", "bin/quality", "--list", group)
  end

  def expect_commands(group, commands)
    stdout, stderr, status = list(group)
    expect([ status.success?, stderr, stdout.lines.map(&:chomp) ]).to eq([ true, "", commands ])
  end

  it "lists backend lint commands" do
    expect_commands("be", [
      "bundle exec rubocop --cache false",
      "bundle exec fasterer"
    ])
  end

  it "lists frontend lint commands" do
    expect_commands("fe", [
      "bundle exec erb_lint --lint-all",
      "bin/rails tailwindcss:build"
    ])
  end

  it "lists additional checks" do
    expect_commands("checks", check_commands)
  end

  it "rejects unknown groups" do
    expect(list("unknown").then { [ _1[2].success?, _1[1] ] }).to eq([
      false, "Usage: bin/quality [be|fe|checks|all]\n"
    ])
  end
end # rubocop:enable RSpec/DescribeClass
