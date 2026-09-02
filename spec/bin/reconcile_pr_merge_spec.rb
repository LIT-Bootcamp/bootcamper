# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
require "fileutils"
require "json"
require "open3"
require "tmpdir"

RSpec.describe "bin/reconcile_pr_merge" do
  def run_reconciliation(pr_body:, issues:, pull_requests: [], completion_tickets: nil, push_succeeds: true)
    Dir.mktmpdir("reconcile-pr-merge") do |dir|
      bin = File.join(dir, "bin")
      fake_bin = File.join(dir, "fake-bin")
      result = File.join(dir, "result")
      events = File.join(dir, "events")
      FileUtils.mkdir_p([ bin, fake_bin ])
      FileUtils.cp("bin/reconcile_pr_merge", bin)

      File.write(File.join(bin, "project_status_update"), <<~SH)
        #!/usr/bin/env bash
        printf 'project:%s:%s:%s\n' "$PROJECT_STATUS" "$PROJECT_ITEM_NUMBER" "$PROJECT_SOURCE_VERSION" >> "$EVENTS_FILE"
        printf '%s %s %s' "$PROJECT_STATUS" "$PROJECT_ITEM_NUMBER" "$PROJECT_SOURCE_VERSION" > "$RESULT_FILE"
      SH
      FileUtils.chmod(0o755, File.join(bin, "project_status_update"))

      File.write(File.join(bin, "product_factory"), <<~RUBY)
        #!/usr/bin/env ruby
        require "json"

        File.open(ENV.fetch("EVENTS_FILE"), "a") { |file| file.puts("complete:TICKET-011") }
        puts JSON.generate("changed" => true, "tickets" => JSON.parse(ENV.fetch("COMPLETION_TICKETS")))
      RUBY
      FileUtils.chmod(0o755, File.join(bin, "product_factory"))

      File.write(File.join(fake_bin, "git"), <<~RUBY)
        #!/usr/bin/env ruby
        command = ARGV.first
        File.open(ENV.fetch("EVENTS_FILE"), "a") { |file| file.puts(command) }
        exit 1 if command == "diff"
        exit 1 if command == "push" && ENV.fetch("PUSH_SUCCEEDS") != "true"
      RUBY
      FileUtils.chmod(0o755, File.join(fake_bin, "git"))

      File.write(File.join(fake_bin, "gh"), <<~RUBY)
        #!/usr/bin/env ruby
        require "json"

        if ARGV == [ "api", "repos/example/bootcamper/pulls/160" ]
          puts ENV.fetch("PR_JSON")
        elsif ARGV.first(3) == [ "api", "--paginate", "--slurp" ]
          collection = ARGV.last.include?("/pulls?") ? "PULL_REQUESTS_JSON" : "ISSUES_JSON"
          puts JSON.generate([ JSON.parse(ENV.fetch(collection)) ])
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
        "PR_JSON" => JSON.generate(
          "base" => { "ref" => "main" }, "merged" => true, "body" => pr_body,
          "merge_commit_sha" => "abc123", "merged_at" => "2026-09-01T18:00:00Z"
        ),
        "ISSUES_JSON" => JSON.generate(issues),
        "PULL_REQUESTS_JSON" => JSON.generate(pull_requests),
        "COMPLETION_TICKETS" => JSON.generate(completion_tickets || [
          { "id" => "TICKET-011", "state" => "done", "current_version" => 6, "github_issue" => 158 }
        ]),
        "RESULT_FILE" => result,
        "EVENTS_FILE" => events,
        "PUSH_SUCCEEDS" => push_succeeds.to_s,
        "PATH" => "#{fake_bin}:#{ENV.fetch("PATH")}"
      }
      stdout, stderr, status = Open3.capture3(env, "bash", "bin/reconcile_pr_merge", chdir: dir)
      [ stdout, stderr, status, File.exist?(result) ? File.read(result) : nil,
        File.exist?(events) ? File.readlines(events, chomp: true) : [] ]
    end
  end

  it "marks the uniquely mapped factory ticket done" do
    marker = "<!-- product-factory-ticket-id: TICKET-011 -->"
    issue = { "number" => 158, "body" => "Ticket\n\n#{marker}" }

    _stdout, stderr, status, result, events = run_reconciliation(pr_body: marker, issues: [ issue ])

    expect(status).to be_success
    expect(stderr).to eq("")
    expect(result).to eq("done 158 6")
    expect(events.index("complete:TICKET-011")).to be < events.index("push")
    expect(events.index("push")).to be < events.index("project:done:158:6")
  end

  it "fails when a present marker does not map to exactly one issue" do
    marker = "<!-- product-factory-ticket-id: TICKET-011 -->"

    _stdout, stderr, status, result, _events = run_reconciliation(pr_body: marker, issues: [])

    expect(status).not_to be_success
    expect(stderr).to include("Factory marker TICKET-011 does not map to exactly one GitHub issue")
    expect(result).to be_nil
  end

  it "keeps infrastructure pull requests without a marker as a successful no-op" do
    stdout, stderr, status, result, _events = run_reconciliation(pr_body: "Infrastructure only", issues: [])

    expect(status).to be_success
    expect(stdout).to include("has no Product Factory ticket marker")
    expect(stderr).to eq("")
    expect(result).to be_nil
  end

  it "does not update the Project when canonical Git publication fails" do
    marker = "<!-- product-factory-ticket-id: TICKET-011 -->"
    issue = { "number" => 158, "body" => "Ticket\n\n#{marker}" }

    _stdout, _stderr, status, result, events = run_reconciliation(
      pr_body: marker, issues: [ issue ], push_succeeds: false
    )

    expect(status).not_to be_success
    expect(events).to include("complete:TICKET-011", "push")
    expect(events.grep(/\Aproject:/)).to be_empty
    expect(result).to be_nil
  end

  it "preserves a newly unblocked ticket projection when it already has an active pull request" do
    merged_marker = "<!-- product-factory-ticket-id: TICKET-011 -->"
    active_marker = "<!-- product-factory-ticket-id: TICKET-002 -->"
    issues = [
      { "number" => 158, "body" => merged_marker },
      { "number" => 141, "body" => active_marker }
    ]
    tickets = [
      { "id" => "TICKET-011", "state" => "done", "current_version" => 6, "github_issue" => 158 },
      { "id" => "TICKET-002", "state" => "available", "current_version" => 5, "github_issue" => 141 }
    ]

    stdout, stderr, status, _result, events = run_reconciliation(
      pr_body: merged_marker,
      issues: issues,
      pull_requests: [ { "number" => 166, "body" => active_marker } ],
      completion_tickets: tickets
    )

    expect(status).to be_success
    expect(stderr).to eq("")
    expect(stdout).to include("TICKET-002 has active PR #166; preserving active delivery projection")
    expect(events.grep(/project:/)).to eq([ "project:done:158:6" ])
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
