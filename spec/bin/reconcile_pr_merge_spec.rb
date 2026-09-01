# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe "bin/reconcile_pr_merge" do
  def run_reconciliation(pr_body:, issues:)
    Dir.mktmpdir("reconcile-pr-merge") do |dir|
      bin = File.join(dir, "bin")
      fake_bin = File.join(dir, "fake-bin")
      result = File.join(dir, "result")
      FileUtils.mkdir_p([ bin, fake_bin ])
      FileUtils.cp("bin/reconcile_pr_merge", bin)

      File.write(File.join(bin, "project_status_update"), <<~SH)
        #!/usr/bin/env bash
        printf '%s %s' "$PROJECT_STATUS" "$PROJECT_ITEM_NUMBER" > "$RESULT_FILE"
      SH
      FileUtils.chmod(0o755, File.join(bin, "project_status_update"))

      File.write(File.join(fake_bin, "gh"), <<~RUBY)
        #!/usr/bin/env ruby
        require "json"

        if ARGV == [ "api", "repos/example/bootcamper/pulls/160" ]
          puts ENV.fetch("PR_JSON")
        elsif ARGV.first(3) == [ "api", "--paginate", "--slurp" ]
          puts JSON.generate([ JSON.parse(ENV.fetch("ISSUES_JSON")) ])
        else
          warn "unexpected gh arguments: \#{ARGV.inspect}"
          exit 64
        end
      RUBY
      FileUtils.chmod(0o755, File.join(fake_bin, "gh"))

      env = {
        "GH_TOKEN" => "test-token",
        "REPOSITORY" => "example/bootcamper",
        "PR_NUMBER" => "160",
        "PR_JSON" => JSON.generate("base" => { "ref" => "main" }, "merged" => true, "body" => pr_body),
        "ISSUES_JSON" => JSON.generate(issues),
        "RESULT_FILE" => result,
        "PATH" => "#{fake_bin}:#{ENV.fetch("PATH")}"
      }
      stdout, stderr, status = Open3.capture3(env, "bash", "bin/reconcile_pr_merge", chdir: dir)
      [ stdout, stderr, status, File.exist?(result) ? File.read(result) : nil ]
    end
  end

  it "marks the uniquely mapped factory ticket done" do
    marker = "<!-- product-factory-ticket-id: TICKET-011 -->"
    issue = { "number" => 158, "body" => "Ticket\n\n#{marker}" }

    _stdout, stderr, status, result = run_reconciliation(pr_body: marker, issues: [ issue ])

    expect(status).to be_success
    expect(stderr).to eq("")
    expect(result).to eq("done 158")
  end

  it "fails when a present marker does not map to exactly one issue" do
    marker = "<!-- product-factory-ticket-id: TICKET-011 -->"

    _stdout, stderr, status, result = run_reconciliation(pr_body: marker, issues: [])

    expect(status).not_to be_success
    expect(stderr).to include("Factory marker TICKET-011 does not map to exactly one GitHub issue")
    expect(result).to be_nil
  end

  it "keeps infrastructure pull requests without a marker as a successful no-op" do
    stdout, stderr, status, result = run_reconciliation(pr_body: "Infrastructure only", issues: [])

    expect(status).to be_success
    expect(stdout).to include("has no Product Factory ticket marker")
    expect(stderr).to eq("")
    expect(result).to be_nil
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
