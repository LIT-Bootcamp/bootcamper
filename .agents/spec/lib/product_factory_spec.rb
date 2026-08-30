require "digest"
require "fileutils"
require "open3"
require "tmpdir"
require "yaml"

require_relative "../../../lib/product_factory"

RSpec.describe ProductFactory::Validator do
  def with_product
    Dir.mktmpdir("product-factory") { |dir| yield Pathname(dir) }
  end

  def write_artifact(root, id:, kind:, versions: [ 1 ], state: "proposed", dependencies: [], priority: 1,
                     estimate_days: 1, scenarios: nil, source_versions: {})
    directory = root.join("ideas", "IDEA-001-demo", kind == "idea" ? "idea" : "epics/EPIC-001-demo/#{kind == "ticket" ? "tickets/#{id.downcase}-demo" : id.downcase + "-demo"}")
    version_directory = kind == "epic" ? directory.join("requirements") : directory
    FileUtils.mkdir_p(version_directory)

    versions.each do |version|
      metadata = {
        "id" => id,
        "version" => version,
        "author" => "technical_lead",
        "run_id" => "RUN-20260827T120000Z-a1b2c3",
        "created_at" => "2026-08-27T12:00:00Z",
        "previous_version" => version == 1 ? nil : version - 1,
        "reason" => version == 1 ? nil : "Updated after review",
        "source_versions" => source_versions,
        "assumptions" => [],
        "unresolved_questions" => [],
        "state" => state
      }
      File.write(version_directory.join(format("v%03d.%s", version, kind == "epic" ? "feature" : "md")), "---\n#{YAML.dump(metadata).sub(/\\A---\\n/, "")}---\n# #{id} v#{version}\n")
    end

    current = version_directory.join(format("v%03d.%s", versions.last, kind == "epic" ? "feature" : "md"))
    manifest = {
      "id" => id,
      "kind" => kind,
      "current_version" => versions.last,
      "state" => state,
      "source_versions" => source_versions,
      "content_sha256" => Digest::SHA256.hexdigest(File.binread(current).gsub("\r\n", "\n")),
      "github_issue" => nil,
      "dependencies" => dependencies,
      "priority" => priority,
      "estimate_days" => estimate_days
    }
    manifest["scenarios"] = scenarios unless scenarios.nil?
    File.write(directory.join("manifest.yml"), YAML.dump(manifest))
    directory
  end

  def write_epic_requirements(directory, coverage:)
    version = directory.join("requirements/v001.feature")
    File.write(version, <<~FEATURE)
      #{File.read(version)}
      # requirement_id: REQUIREMENT-001
      Feature: Example outcome

        # scenario_id: SCENARIO-001
        Scenario: Happy path
          Given a starting condition
          When the user acts
          Then the outcome is visible

        # scenario_id: SCENARIO-002
        Scenario: Error path
          Given a failing condition
          When the user acts
          Then the error is visible
    FEATURE
    File.write(directory.join("requirements/coverage.yml"), YAML.dump("requirements" => coverage))
    manifest = YAML.load_file(directory.join("manifest.yml"))
    manifest["content_sha256"] = Digest::SHA256.hexdigest(File.binread(version).gsub("\r\n", "\n"))
    File.write(directory.join("manifest.yml"), YAML.dump(manifest))
  end

  it "accepts a valid immutable version chain" do
    with_product do |root|
      write_artifact(root, id: "IDEA-001", kind: "idea", versions: [ 1, 2 ], state: "human-approved")

      expect(described_class.new(root: root).validate!).to be(true)
    end
  end

  it "reads EPIC versions from their requirements directory" do
    with_product do |root|
      epic = write_artifact(root, id: "EPIC-001", kind: "epic", state: "draft")
      write_epic_requirements(epic, coverage: [ {
        "requirement_id" => "REQUIREMENT-001", "happy_path" => "SCENARIO-001", "edge_or_error" => [ "SCENARIO-002" ]
      } ])

      expect(described_class.new(root: root).validate!).to be(true)
    end
  end

  it "rejects EPIC coverage without an edge or error mapping" do
    with_product do |root|
      epic = write_artifact(root, id: "EPIC-001", kind: "epic", state: "draft")
      write_epic_requirements(epic, coverage: [ { "requirement_id" => "REQUIREMENT-001", "happy_path" => "SCENARIO-001" } ])

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /edge or error/)
    end
  end

  it "rejects EPIC coverage whose happy path is not a Gherkin scenario" do
    with_product do |root|
      epic = write_artifact(root, id: "EPIC-001", kind: "epic", state: "draft")
      write_epic_requirements(epic, coverage: [ {
        "requirement_id" => "REQUIREMENT-001", "happy_path" => "SCENARIO-999", "edge_or_error" => [ "SCENARIO-002" ]
      } ])

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /happy path scenario/)
    end
  end

  it "rejects a missing reason for change" do
    with_product do |root|
      directory = write_artifact(root, id: "IDEA-001", kind: "idea", versions: [ 1, 2 ])
      version = directory.join("v002.md")
      File.write(version, File.read(version).sub("reason: Updated after review", "reason: "))
      manifest = YAML.load_file(directory.join("manifest.yml"))
      manifest["content_sha256"] = Digest::SHA256.hexdigest(File.binread(version).gsub("\r\n", "\n"))
      File.write(directory.join("manifest.yml"), YAML.dump(manifest))

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /reason/)
    end
  end

  it "rejects a content hash mismatch" do
    with_product do |root|
      directory = write_artifact(root, id: "IDEA-001", kind: "idea")
      manifest = YAML.load_file(directory.join("manifest.yml"))
      manifest["content_sha256"] = "0" * 64
      File.write(directory.join("manifest.yml"), YAML.dump(manifest))

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /content hash/)
    end
  end

  it "rejects a manifest that is not a mapping" do
    with_product do |root|
      manifest = root.join("ideas/IDEA-001-demo/idea/manifest.yml")
      FileUtils.mkdir_p(manifest.dirname)
      File.write(manifest, "---\n- not a mapping\n")

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /manifest must be a mapping/)
    end
  end

  it "rejects a changed committed historical version" do
    Dir.mktmpdir("product-factory-git") do |dir|
      root = Pathname(dir).join("product")
      [ [ "init", "-q" ], [ "config", "user.email", "factory@example.test" ], [ "config", "user.name", "Factory" ] ].each do |args|
        _stdout, stderr, status = Open3.capture3("git", "-C", dir, *args)
        raise stderr unless status.success?
      end
      directory = write_artifact(root, id: "IDEA-001", kind: "idea", versions: [ 1, 2 ], state: "human-approved")
      expect(described_class.new(root: root).validate!).to be(true)
      [ [ "add", "." ], [ "commit", "-qm", "fixture" ] ].each do |args|
        _stdout, stderr, status = Open3.capture3("git", "-C", dir, *args)
        raise stderr unless status.success?
      end
      version = directory.join("v001.md")
      File.write(version, "#{File.read(version)}changed after commit\n")
      committed, _stderr, status = Open3.capture3("git", "-C", dir, "show", "HEAD:product/ideas/IDEA-001-demo/idea/v001.md")
      expect(status).to be_success
      expect(committed).not_to eq(File.binread(version))

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /differs from Git/)
    end
  end

  it "rejects an illegal lifecycle transition" do
    with_product do |root|
      write_artifact(root, id: "TICKET-001", kind: "ticket", versions: [ 1, 2 ], state: "done", scenarios: [ "SCENARIO-001" ])
      directory = root.join("ideas/IDEA-001-demo/epics/EPIC-001-demo/tickets/ticket-001-demo")
      version = directory.join("v001.md")
      File.write(version, File.read(version).sub("state: done", "state: draft"))

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /lifecycle/)
    end
  end

  it "rejects a dependency cycle" do
    with_product do |root|
      write_artifact(root, id: "TICKET-001", kind: "ticket", dependencies: [ "TICKET-002" ], scenarios: [ "SCENARIO-001" ])
      write_artifact(root, id: "TICKET-002", kind: "ticket", dependencies: [ "TICKET-001" ], scenarios: [ "SCENARIO-002" ])

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /dependency cycle/)
    end
  end

  it "rejects a ticket over two ideal days" do
    with_product do |root|
      write_artifact(root, id: "TICKET-001", kind: "ticket", estimate_days: 2.1, scenarios: [ "SCENARIO-001" ])

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /two ideal days/)
    end
  end

  it "rejects uncovered scenarios and orphan tickets" do
    with_product do |root|
      write_artifact(root, id: "TICKET-001", kind: "ticket", scenarios: [])
      coverage = root.join("ideas/IDEA-001-demo/epics/EPIC-001-demo/requirements/coverage.yml")
      FileUtils.mkdir_p(coverage.dirname)
      File.write(coverage, YAML.dump("scenarios" => [ { "id" => "SCENARIO-001", "tickets" => [] } ]))

      expect { described_class.new(root: root).validate! }.to raise_error(ProductFactory::ValidationError, /uncovered scenarios.*orphan tickets/m)
    end
  end
end

RSpec.describe ProductFactory::Repository do
  def with_product
    Dir.mktmpdir("product-factory") { |dir| yield Pathname(dir) }
  end

  def write_manifest(root, id:, kind:, state: "available", version: 1, dependencies: [], priority: 1)
    path = root.join("ideas", "IDEA-001-demo", "#{id.downcase}-demo")
    FileUtils.mkdir_p(path)
    File.write(path.join("manifest.yml"), YAML.dump(
      "id" => id, "kind" => kind, "current_version" => version, "state" => state,
      "content_sha256" => (id * 64)[0, 64], "dependencies" => dependencies,
      "priority" => priority, "estimate_days" => 1, "source_versions" => {}
    ))
    path
  end

  def successful_run(root, phase: "backlog-idea")
    run = ProductFactory::Run.start(root: root, phase: phase, source_ids: [])
    run.finish!(status: "success", output_ids: [])
  end

  it "reports new, changed, deleted, newly unblocked, and unchanged IDs" do
    with_product do |root|
      write_manifest(root, id: "IDEA-001", kind: "idea")
      changed = write_manifest(root, id: "TICKET-001", kind: "ticket")
      write_manifest(root, id: "TICKET-002", kind: "ticket", dependencies: [ "TICKET-003" ])
      write_manifest(root, id: "TICKET-003", kind: "ticket", state: "in-progress")
      deleted = write_manifest(root, id: "EPIC-001", kind: "epic")
      successful_run(root)

      manifest = YAML.load_file(changed.join("manifest.yml"))
      manifest["current_version"] = 2
      File.write(changed.join("manifest.yml"), YAML.dump(manifest))
      manifest = YAML.load_file(root.join("ideas/IDEA-001-demo/ticket-003-demo/manifest.yml"))
      manifest["state"] = "done"
      File.write(root.join("ideas/IDEA-001-demo/ticket-003-demo/manifest.yml"), YAML.dump(manifest))
      FileUtils.rm_rf(deleted)
      write_manifest(root, id: "TICKET-004", kind: "ticket")

      statuses = described_class.new(root: root).changes(phase: "backlog-idea").to_h { |change| [ change.id, change.status ] }

      expect(statuses).to include(
        "IDEA-001" => :unchanged,
        "TICKET-001" => :changed,
        "TICKET-002" => :newly_unblocked,
        "EPIC-001" => :deleted,
        "TICKET-004" => :new
      )
    end
  end

  it "returns no actionable IDs after an unchanged successful run" do
    with_product do |root|
      write_manifest(root, id: "IDEA-001", kind: "idea")
      successful_run(root)

      changes = described_class.new(root: root).changes(phase: "backlog-idea")

      expect(changes.reject { |change| change.status == :unchanged }).to be_empty
    end
  end

  it "selects priority before ID among available dependency-safe tickets" do
    with_product do |root|
      slow = write_manifest(root, id: "TICKET-010", kind: "ticket", priority: 2)
      fast = write_manifest(root, id: "TICKET-002", kind: "ticket", priority: 1)
      write_manifest(root, id: "TICKET-001", kind: "ticket", priority: 1, dependencies: [ "TICKET-099" ])
      write_manifest(root, id: "TICKET-099", kind: "ticket", state: "in-progress")

      expect(described_class.new(root: root).next_ticket).to eq(fast.join("manifest.yml"))
      expect(described_class.new(root: root).next_ticket).not_to eq(slow.join("manifest.yml"))
    end
  end

  it "derives GitHub projection data from the immutable ticket and lineage path" do
    with_product do |root|
      directory = write_manifest(root, id: "TICKET-001", kind: "ticket")
      version = directory.join("v001.md")
      File.write(version, <<~MARKDOWN)
        ---
        run_id: RUN-20260827T120000Z-a1b2c3
        ---
        # TICKET-001 Publish catalog

        Show the public catalog.
      MARKDOWN

      item = described_class.new(root: root).snapshot.fetch("TICKET-001")

      expect(item).to include(
        "title" => "TICKET-001 Publish catalog",
        "body" => include("Show the public catalog."),
        "idea_id" => "IDEA-001",
        "factory_run" => "RUN-20260827T120000Z-a1b2c3"
      )
    end
  end
end

RSpec.describe ProductFactory::Run do
  it "rejects a second finish for the same run" do
    Dir.mktmpdir("product-factory-run") do |dir|
      run = described_class.start(root: dir, phase: "backlog-idea", source_ids: [])
      run.finish!(status: "success", output_ids: [ "IDEA-001" ])

      expect { run.finish!(status: "escalated", output_ids: [], error: "late rewrite") }.to raise_error(ProductFactory::ValidationError, /already finished/)
    end
  end

  it "moves an unfinished run into a ticket worktree root" do
    Dir.mktmpdir("product-factory-run-source") do |source|
      Dir.mktmpdir("product-factory-run-destination") do |destination|
        run = described_class.start(root: source, phase: "implement", source_ids: [])
        moved = described_class.move!(source_root: source, destination_root: destination, id: run.id)

        expect(Pathname(source).join("factory-log", "#{run.id}-started.yml")).not_to exist
        expect(Pathname(destination).join("factory-log", "#{run.id}-started.yml")).to exist
        expect { moved.finish!(status: "success", output_ids: [ "TICKET-001" ]) }.not_to raise_error
      end
    end
  end
end

RSpec.describe ProductFactory::ClaimRegistry do
  it "allows only one process to claim a ticket" do
    Dir.mktmpdir("product-factory-claims") do |dir|
      registry = described_class.new(git_common_dir: dir)
      registry.claim!(ticket_id: "TICKET-001", run_id: "RUN-1")

      expect { registry.claim!(ticket_id: "TICKET-001", run_id: "RUN-2") }.to raise_error(ProductFactory::ClaimConflict)
    end
  end

  it "releases a claim owned by the matching run" do
    Dir.mktmpdir("product-factory-claims") do |dir|
      registry = described_class.new(git_common_dir: dir)
      registry.claim!(ticket_id: "TICKET-001", run_id: "RUN-1")
      registry.release!(ticket_id: "TICKET-001", run_id: "RUN-1")

      expect { registry.claim!(ticket_id: "TICKET-001", run_id: "RUN-2") }.not_to raise_error
    end
  end
end

RSpec.describe "bin/product_factory" do
  it "validates an empty product root and prints JSON" do
    Dir.mktmpdir("product-factory-cli") do |dir|
      stdout, stderr, status = Open3.capture3("bin/product_factory", "validate", "--root", dir)

      expect(status).to be_success, stderr
      expect(JSON.parse(stdout)).to include("valid" => true)
    end
  end

  it "moves and finishes a run through the CLI in another worktree root" do
    Dir.mktmpdir("product-factory-cli-source") do |source|
      Dir.mktmpdir("product-factory-cli-destination") do |destination|
        started, stderr, status = Open3.capture3(
          "bin/product_factory", "start-run", "--root", source, "--phase", "implement"
        )
        expect(status).to be_success, stderr
        run_id = JSON.parse(started).fetch("run_id")

        _stdout, stderr, status = Open3.capture3(
          "bin/product_factory", "move-run", "--root", source,
          "--destination-root", destination, "--run-id", run_id
        )
        expect(status).to be_success, stderr

        _stdout, stderr, status = Open3.capture3(
          "bin/product_factory", "finish-run", "--root", destination,
          "--run-id", run_id, "--status", "success"
        )
        expect(status).to be_success, stderr
        expect(Pathname(destination).join("factory-log", "#{run_id}-finished.yml")).to exist
      end
    end
  end
end
