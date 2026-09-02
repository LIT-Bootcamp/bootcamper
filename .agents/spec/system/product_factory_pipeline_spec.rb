# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "tmpdir"
require "yaml"

require_relative "../../../lib/product_factory"

# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe "Product Factory offline pipeline" do
  let(:fixture_root) { Pathname(__dir__).join("../fixtures/product_factory/approved_idea").expand_path }

  def with_fixture
    Dir.mktmpdir("product-factory-pipeline") do |directory|
      root = Pathname(directory)
      FileUtils.cp_r(fixture_root.children, root)
      yield root, root.join("product")
    end
  end

  def finish_checkpoint(product, phase: "backlog-idea")
    run = ProductFactory::Run.start(root: product, phase: phase, source_ids: [ "IDEA-001" ])
    run.finish!(status: "success", output_ids: [])
  end

  it "proves first-run, no-op, changed-artifact, selection, validation, and GitHub planning behavior" do
    with_fixture do |root, product|
      repository = ProductFactory::Repository.new(root: product)
      first_scan = repository.changes(phase: "backlog-idea").select { |change| change.kind == "ticket" }
      expect(first_scan.map { |change| change.status.to_s }).to contain_exactly("new", "new", "new")

      finish_checkpoint(product)
      second_scan = repository.changes(phase: "backlog-idea").reject { |change| change.status == :unchanged }
      expect(second_scan).to be_empty

      epic = product.join("ideas/IDEA-001-guided-learning/epics/EPIC-001-admissions")
      staged_product = root.join("staged-product")
      FileUtils.cp_r(product, staged_product)
      staged_epic = staged_product.join("ideas/IDEA-001-guided-learning/epics/EPIC-001-admissions")
      staged_version = staged_epic.join("requirements/v004.feature")
      FileUtils.cp(root.join("updates/EPIC-001-v004.feature"), staged_version)
      staged_manifest_path = staged_epic.join("manifest.yml")
      manifest = YAML.safe_load(File.read(staged_manifest_path), aliases: false)
      manifest["current_version"] = 4
      manifest["state"] = "TL-approved"
      manifest["content_sha256"] = Digest::SHA256.hexdigest(File.binread(staged_version).gsub("\r\n", "\n"))
      File.write(staged_manifest_path, YAML.dump(manifest))
      expect { ProductFactory::Repository.new(root: staged_product).validate! }.not_to raise_error

      updated_version = epic.join("requirements/v004.feature")
      manifest_path = epic.join("manifest.yml")
      FileUtils.cp(staged_version, updated_version)
      FileUtils.cp(staged_manifest_path, manifest_path)

      changed_scan = repository.changes(phase: "backlog-idea")
      expect(changed_scan.map { |change| [ change.id, change.status.to_s ] }).to include([ "EPIC-001", "changed" ])
      expect(YAML.safe_load(File.read(updated_version).match(/\A---\n(.*?)\n---\n/m)[1], aliases: false).fetch("reason")).not_to be_empty

      expect(YAML.safe_load(File.read(repository.next_ticket), aliases: false).fetch("id")).to eq("TICKET-002")
      expect { repository.validate! }.not_to raise_error

      local_tickets = repository.snapshot.select { |_id, item| item["kind"] == "ticket" }
      remote = JSON.parse(File.read(root.join("remote/github.json")))
      operations = ProductFactory::GitHubPlan.new(local: local_tickets, remote: remote).operations

      expect(operations).to include(have_attributes(action: :close_superseded, ticket_id: "TICKET-003", issue_number: 203))
      expect(operations).to include(have_attributes(action: :project_add, ticket_id: "TICKET-002", issue_number: 202))
      expect(operations).to include(have_attributes(action: :project_field, ticket_id: "TICKET-001", attributes: include("field" => "Status", "value" => "done")))
    end
  end

  it "classifies a ticket as newly unblocked after its merged dependency becomes done" do
    with_fixture do |_root, product|
      ticket = product.join("ideas/IDEA-001-guided-learning/epics/EPIC-001-admissions/tickets/TICKET-001-accept-application")
      manifest_path = ticket.join("manifest.yml")
      completed_manifest = YAML.safe_load(File.read(manifest_path), aliases: false)
      pending_manifest = completed_manifest.merge(
        "current_version" => 6,
        "state" => "ready-for-human-merge",
        "content_sha256" => Digest::SHA256.hexdigest(File.binread(ticket.join("v006.md")).gsub("\r\n", "\n"))
      )
      File.write(manifest_path, YAML.dump(pending_manifest))
      finish_checkpoint(product)
      File.write(manifest_path, YAML.dump(completed_manifest))

      changes = ProductFactory::Repository.new(root: product).changes(phase: "backlog-idea").to_h { |change| [ change.id, change.status ] }

      expect(changes).to include("TICKET-001" => :changed, "TICKET-002" => :newly_unblocked)
    end
  end

  it "publishes merged completion and newly unblocked tickets as immutable versions" do
    with_fixture do |_root, product|
      completed = product.join("ideas/IDEA-001-guided-learning/epics/EPIC-001-admissions/tickets/TICKET-001-accept-application")
      dependent = product.join("ideas/IDEA-001-guided-learning/epics/EPIC-001-admissions/tickets/TICKET-002-show-next-action")
      FileUtils.rm(completed.join("v007.md"))
      FileUtils.rm(dependent.join("v003.md"))

      completed_manifest = YAML.safe_load(File.read(completed.join("manifest.yml")), aliases: false)
      completed_manifest.merge!(
        "current_version" => 6,
        "state" => "ready-for-human-merge",
        "content_sha256" => Digest::SHA256.hexdigest(File.binread(completed.join("v006.md")).gsub("\r\n", "\n"))
      )
      File.write(completed.join("manifest.yml"), YAML.dump(completed_manifest))

      dependent_manifest = YAML.safe_load(File.read(dependent.join("manifest.yml")), aliases: false)
      dependent_manifest.merge!(
        "current_version" => 2,
        "state" => "backlog-ready",
        "content_sha256" => Digest::SHA256.hexdigest(File.binread(dependent.join("v002.md")).gsub("\r\n", "\n"))
      )
      File.write(dependent.join("manifest.yml"), YAML.dump(dependent_manifest))

      stdout, stderr, status = Open3.capture3(
        "bin/product_factory", "complete-ticket", "--root", product.to_s,
        "--ticket", "TICKET-001", "--run-id", "RUN-20260901T180000Z-a1b2c3",
        "--pull-request", "77", "--merge-commit", "abc123", "--created-at", "2026-09-01T18:00:00Z"
      )
      expect(status).to be_success, stderr
      result = JSON.parse(stdout).fetch("tickets")

      expect(result.map { |ticket| [ ticket.fetch("id"), ticket.fetch("state") ] }).to contain_exactly(
        [ "TICKET-001", "done" ], [ "TICKET-002", "available" ]
      )
      expect(YAML.safe_load(File.read(completed.join("manifest.yml")), aliases: false)).to include(
        "current_version" => 7, "state" => "done", "merged_pull_request" => 77
      )
      expect(YAML.safe_load(File.read(dependent.join("manifest.yml")), aliases: false)).to include(
        "current_version" => 3, "state" => "available"
      )
      changelog = product.join("ideas/IDEA-001-guided-learning/changelog.md")
      expect(File.read(changelog)).to include("TICKET-001", "TICKET-002", "RUN-20260901T180000Z-a1b2c3")

      ProductFactory::Repository.new(root: product).complete_ticket!(
        ticket_id: "TICKET-001",
        run_id: "RUN-20260901T180000Z-a1b2c3",
        pull_request: 77,
        merge_commit: "abc123"
      )
      expect(YAML.safe_load(File.read(completed.join("manifest.yml")), aliases: false)).to include(
        "current_version" => 7, "state" => "done"
      )
      expect { ProductFactory::Repository.new(root: product).validate! }.not_to raise_error
    end
  end

  it "moves the implementation run record into the claimed ticket root before finishing" do
    with_fixture do |root, product|
      destination = root.join("ticket-worktree/product")
      FileUtils.mkdir_p(destination.dirname)
      FileUtils.cp_r(product, destination)
      run = ProductFactory::Run.start(root: product, phase: "implement", source_ids: [])

      ProductFactory::Run.move!(source_root: product, destination_root: destination, id: run.id)
      moved = ProductFactory::Run.new(path: destination.join("factory-log/#{run.id}-started.yml"), id: run.id)
      moved.finish!(status: "success", output_ids: [ "TICKET-002" ])

      expect(product.join("factory-log/#{run.id}-started.yml")).not_to exist
      expect(destination.join("factory-log/#{run.id}-finished.yml")).to exist
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
