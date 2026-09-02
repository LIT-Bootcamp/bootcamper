require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "securerandom"
require "time"
require "tmpdir"
require "yaml"
require_relative "product_factory/github_plan"

module ProductFactory
  Change = Data.define(:id, :kind, :status, :current_version, :previous_version)

  class ValidationError < StandardError; end
  class ClaimConflict < StandardError; end

  class Validator
    LIFECYCLES = {
      "idea" => %w[proposed human-approved analyzed],
      "epic" => %w[draft BA-ready TL-review TL-approved],
      "ticket" => %w[draft backlog-ready available in-progress in-review ready-for-human-merge done]
    }.freeze
    EXCEPTIONAL_STATES = %w[blocked superseded escalated].freeze
    MANIFEST_KEYS = %w[id kind current_version state source_versions content_sha256 github_issue dependencies priority estimate_days].freeze
    VERSION_KEYS = %w[id version author run_id created_at previous_version reason source_versions assumptions unresolved_questions state].freeze

    def initialize(root:)
      @root = Pathname(root)
      @errors = []
    end

    def validate!
      artifacts = artifact_records
      artifacts.each { |artifact| validate_artifact(artifact) }
      validate_dependencies(artifacts)
      validate_coverage(artifacts)
      raise ValidationError, @errors.join("; ") unless @errors.empty?

      true
    end

    private

    def artifact_records
      @root.glob("ideas/**/manifest.yml").sort.filter_map do |path|
        manifest = load_yaml(path)
        unless manifest.is_a?(Hash)
          error(path, "manifest must be a mapping")
          next
        end

        { path: path, directory: path.dirname, manifest: manifest, versions: version_files(path.dirname, manifest["kind"]) }
      end
    end

    def validate_artifact(artifact)
      manifest = artifact[:manifest]
      id = manifest["id"]
      missing = MANIFEST_KEYS.reject { |key| manifest.key?(key) }
      error(id || artifact[:path], "missing manifest keys: #{missing.join(", ")}") unless missing.empty?
      return unless missing.empty?

      kind = manifest["kind"]
      error(id, "invalid stable ID") unless id.to_s.match?(/\A(?:IDEA|EPIC|TICKET)-\d{3,}\z/)
      error(id, "invalid kind") unless LIFECYCLES.key?(kind)
      error(id, "invalid lifecycle state") unless LIFECYCLES.fetch(kind) { [] }.include?(manifest["state"]) || EXCEPTIONAL_STATES.include?(manifest["state"])
      error(id, "invalid current version") unless manifest["current_version"].is_a?(Integer) && manifest["current_version"].positive?
      error(id, "invalid content hash") unless manifest["content_sha256"].to_s.match?(/\A[0-9a-f]{64}\z/)
      error(id, "dependencies must be an array") unless manifest["dependencies"].is_a?(Array)
      error(id, "source_versions must be a mapping") unless manifest["source_versions"].is_a?(Hash)
      error(id, "priority must be numeric") unless manifest["priority"].is_a?(Numeric)
      error(id, "estimate_days must be numeric") unless manifest["estimate_days"].is_a?(Numeric)
      error(id, "ticket exceeds two ideal days") if kind == "ticket" && manifest["estimate_days"].to_f > 2

      validate_versions(artifact) if missing.empty? && LIFECYCLES.key?(kind)
    end

    def validate_versions(artifact)
      manifest = artifact[:manifest]
      id = manifest["id"]
      versions = artifact[:versions]
      expected = (1..manifest["current_version"]).to_a
      error(id, "version ancestry is incomplete") unless versions.keys.sort == expected
      current_path = versions[manifest["current_version"]]
      return unless current_path

      error(id, "content hash mismatch") unless digest(current_path) == manifest["content_sha256"]
      prior_state = nil
      versions.keys.sort.each do |number|
        validate_git_immutability(id, versions[number])
        metadata = front_matter(versions[number])
        missing = VERSION_KEYS.reject { |key| metadata.key?(key) }
        error(id, "version #{number} missing keys: #{missing.join(", ")}") unless missing.empty?
        next unless missing.empty?

        error(id, "version metadata ID mismatch") unless metadata["id"] == id
        error(id, "version metadata number mismatch") unless metadata["version"] == number
        error(id, "invalid run ID") unless metadata["run_id"].to_s.match?(/\ARUN-\d{8}T\d{6}Z-[0-9a-f]{6}\z/)
        begin
          Time.iso8601(metadata["created_at"])
        rescue ArgumentError, TypeError
          error(id, "invalid creation time")
        end
        if number == 1
          error(id, "first version has a predecessor") unless metadata["previous_version"].nil?
        else
          error(id, "version ancestry predecessor mismatch") unless metadata["previous_version"] == number - 1
          error(id, "missing reason for change") if metadata["reason"].to_s.strip.empty?
        end
        validate_transition(id, manifest["kind"], prior_state, metadata["state"], versions, number)
        prior_state = metadata["state"]
      end
      error(id, "manifest state does not match current version") unless prior_state == manifest["state"]
    end

    def validate_transition(id, kind, previous, current, versions, number)
      return if previous.nil? && (LIFECYCLES.fetch(kind).include?(current) || EXCEPTIONAL_STATES.include?(current))
      return if previous == current || EXCEPTIONAL_STATES.include?(current)

      if EXCEPTIONAL_STATES.include?(previous)
        before_exception = number > 2 ? front_matter(versions[number - 2])["state"] : nil
        return if current == before_exception
      elsif LIFECYCLES.fetch(kind).index(current) == LIFECYCLES.fetch(kind).index(previous).to_i + 1
        return
      end
      error(id, "illegal lifecycle transition #{previous} -> #{current}")
    end

    def validate_dependencies(artifacts)
      tickets = artifacts.select { |artifact| artifact[:manifest]["kind"] == "ticket" }.to_h { |artifact| [ artifact[:manifest]["id"], artifact[:manifest] ] }
      tickets.each do |id, manifest|
        manifest.fetch("dependencies") { [] }.each { |dependency| error(id, "missing dependency #{dependency}") unless tickets.key?(dependency) }
      end
      visited = {}
      visiting = {}
      tickets.each_key { |id| detect_cycle(id, tickets, visited, visiting) }
    end

    def detect_cycle(id, tickets, visited, visiting)
      return if visited[id]
      if visiting[id]
        error(id, "dependency cycle")
        return
      end

      visiting[id] = true
      tickets.fetch(id).fetch("dependencies") { [] }.each { |dependency| detect_cycle(dependency, tickets, visited, visiting) if tickets.key?(dependency) }
      visiting.delete(id)
      visited[id] = true
    end

    def validate_coverage(artifacts)
      validate_requirement_coverage(artifacts)
      coverage = @root.glob("ideas/**/coverage.yml").sort.flat_map do |path|
        data = load_yaml(path)
        data.is_a?(Hash) && data["scenarios"].is_a?(Array) ? data["scenarios"] : []
      end
      coverage.each { |row| error("coverage", "uncovered scenarios #{row["id"]}") if !row.is_a?(Hash) || !row["tickets"].is_a?(Array) || row["tickets"].empty? }
      covered_pairs = coverage.flat_map { |row| row.is_a?(Hash) ? Array(row["tickets"]).map { |ticket| [ ticket, row["id"] ] } : [] }
      artifacts.select { |artifact| artifact[:manifest]["kind"] == "ticket" }.each do |artifact|
        id = artifact[:manifest]["id"]
        scenarios = artifact[:manifest]["scenarios"]
        valid = scenarios.is_a?(Array) && scenarios.any? && scenarios.all? { |scenario| covered_pairs.include?([ id, scenario ]) }
        error(id, "orphan tickets") unless valid
      end
    end

    def validate_requirement_coverage(artifacts)
      artifacts.select { |artifact| artifact[:manifest]["kind"] == "epic" }.each do |artifact|
        id = artifact[:manifest]["id"]
        requirements, scenarios = gherkin_ids(artifact[:versions][artifact[:manifest]["current_version"]])
        error(id, "Gherkin has no requirement IDs") if requirements.empty?
        error(id, "Gherkin has no scenario IDs") if scenarios.empty?

        coverage = load_yaml(artifact[:directory].join("requirements/coverage.yml"))
        rows = coverage.is_a?(Hash) ? coverage["requirements"] : nil
        unless rows.is_a?(Array)
          error(id, "missing requirement coverage")
          next
        end

        mapped = rows.filter_map { |row| row["requirement_id"] if row.is_a?(Hash) }
        requirements.each { |requirement| error(id, "missing coverage for #{requirement}") unless mapped.include?(requirement) }
        mapped.each { |requirement| error(id, "unknown coverage requirement #{requirement}") unless requirements.include?(requirement) }
        rows.each do |row|
          next unless row.is_a?(Hash)

          requirement = row["requirement_id"]
          happy_path = row["happy_path"]
          edge_or_error = row["edge_or_error"]
          error(id, "#{requirement}: invalid happy path scenario") unless scenarios.include?(happy_path)
          unless edge_or_error.is_a?(Array)
            error(id, "#{requirement}: missing edge or error mapping")
            next
          end
          edge_or_error.each { |scenario| error(id, "#{requirement}: invalid edge or error scenario") unless scenarios.include?(scenario) }
        end
      end
    end

    def gherkin_ids(path)
      return [ [], [] ] unless path

      content = File.binread(path).gsub("\r\n", "\n")
      requirements = content.scan(/^\s*#\s*requirement_id:\s*(REQUIREMENT-\d{3,})\s*$/).flatten.uniq
      scenarios = content.scan(/^\s*#\s*scenario_id:\s*(SCENARIO-\d{3,})\s*$/).flatten.uniq
      [ requirements, scenarios ]
    end

    def version_files(directory, kind)
      version_directory = kind == "epic" ? directory.join("requirements") : directory
      return {} unless version_directory.directory?

      version_directory.children.each_with_object({}) do |path, files|
        match = path.basename.to_s.match(/\Av(\d{3,})\.(?:md|feature)\z/)
        files[match[1].to_i] = path if match
      end
    end

    def front_matter(path)
      content = File.binread(path).gsub("\r\n", "\n")
      match = content.match(/\A---\n(.*?)\n---\n/m)
      return {} unless match

      YAML.safe_load(match[1], aliases: false) || {}
    rescue Psych::Exception
      {}
    end

    def load_yaml(path)
      YAML.safe_load(File.read(path), aliases: false) || {}
    rescue Psych::Exception
      nil
    end

    def validate_git_immutability(id, path)
      root = git_root
      return unless root

      relative_path = path.realpath.relative_path_from(root.realpath).to_s
      content, _stderr, status = Open3.capture3("git", "-C", root.to_s, "show", "HEAD:#{relative_path}")
      return unless status.success?

      error(id, "version #{path.basename} differs from Git") unless content.b == File.binread(path)
    end

    def git_root
      return @git_root if defined?(@git_root)

      output, _stderr, status = Open3.capture3("git", "-C", @root.to_s, "rev-parse", "--show-toplevel")
      @git_root = status.success? ? Pathname(output.strip) : nil
    end

    def digest(path)
      Digest::SHA256.hexdigest(File.binread(path).gsub("\r\n", "\n"))
    end

    def error(id, message)
      @errors << "#{id}: #{message}"
    end
  end

  class Repository
    def initialize(root:) = @root = Pathname(root)
    def validate! = Validator.new(root: @root).validate!

    def changes(phase:)
      current = snapshot
      previous = successful_snapshot(phase) || {}
      (current.keys | previous.keys).sort.map do |id|
        item = current[id]
        prior = previous[id]
        status = if item.nil?
          :deleted
        elsif prior.nil?
          :new
        elsif item == prior
          :unchanged
        elsif item["kind"] == "ticket" && item["state"] == "available" && item["dependency_safe"] && (!prior["dependency_safe"] || prior["state"] != "available")
          :newly_unblocked
        else
          :changed
        end
        Change.new(id, (item || prior)["kind"], status, item && item["current_version"], prior && prior["current_version"])
      end
    end

    def next_ticket(ticket_id: nil)
      tickets = snapshot.values.select { |item| item["kind"] == "ticket" && item["state"] == "available" && item["dependency_safe"] }
      selected = if ticket_id
        tickets.find { |ticket| ticket["id"] == ticket_id } ||
          raise(ValidationError, "#{ticket_id} is not available and dependency-safe")
      else
        tickets.min_by { |ticket| [ ticket["priority"].to_f, ticket["id"] ] }
      end
      selected && Pathname(selected["manifest_path"])
    end

    def complete_ticket!(ticket_id:, run_id:, pull_request:, merge_commit:, created_at: Time.now.utc.iso8601)
      validate!
      current = snapshot.fetch(ticket_id) { raise ValidationError, "unknown ticket #{ticket_id}" }
      raise ValidationError, "#{ticket_id} is not a ticket" unless current["kind"] == "ticket"
      unless %w[ready-for-human-merge done].include?(current["state"])
        raise ValidationError, "#{ticket_id} must be ready-for-human-merge before completion"
      end
      if current["state"] == "done" && current["merged_pull_request"] && current["merged_pull_request"] != pull_request
        raise ValidationError, "#{ticket_id} was completed by PR ##{current["merged_pull_request"]}"
      end

      changed_ids = []
      Dir.mktmpdir("product-factory-completion") do |directory|
        staged_root = Pathname(directory).join("product")
        FileUtils.mkdir_p(staged_root)
        FileUtils.cp_r(@root.children, staged_root)
        staged = self.class.new(root: staged_root)

        if current["state"] != "done"
          staged.send(:advance_ticket!, ticket_id, state: "done", run_id: run_id, created_at: created_at,
            reason: "PR ##{pull_request} merged as #{merge_commit}.", merged_pull_request: pull_request)
          changed_ids << ticket_id
        end

        staged.snapshot.values.select do |ticket|
          ticket["kind"] == "ticket" && ticket["state"] == "backlog-ready" && ticket["dependency_safe"]
        end.sort_by { |ticket| ticket["id"] }.each do |ticket|
          staged.send(:advance_ticket!, ticket["id"], state: "available", run_id: run_id, created_at: created_at,
            reason: "Dependencies completed after PR ##{pull_request}; ticket is now dependency-safe.")
          changed_ids << ticket["id"]
        end

        staged.validate!
        changed_ids.each do |id|
          source = staged.send(:ticket_directory, id)
          destination = ticket_directory(id)
          version = YAML.safe_load(File.read(source.join("manifest.yml")), aliases: false).fetch("current_version")
          FileUtils.cp(source.join(format("v%03d.md", version)), destination)
          FileUtils.cp(source.join("manifest.yml"), destination)
        end
        changed_ids.map { |id| staged.send(:idea_changelog, staged.send(:ticket_directory, id)) }.uniq.each do |source|
          destination = @root.join(source.relative_path_from(staged_root))
          FileUtils.mkdir_p(destination.dirname)
          FileUtils.cp(source, destination)
        end
      end
      validate!

      current_snapshot = snapshot
      ([ ticket_id ] + changed_ids).uniq.map do |id|
        current_snapshot.fetch(id).slice("id", "state", "current_version", "github_issue")
      end
    end

    def snapshot
      records = @root.glob("ideas/**/manifest.yml").sort.filter_map do |path|
        manifest = YAML.safe_load(File.read(path), aliases: false)
        next unless manifest.is_a?(Hash) && manifest["id"]

        item = manifest.merge("manifest_path" => path.to_s)
        enrich_ticket_projection!(item, path) if manifest["kind"] == "ticket"
        [ manifest["id"], item ]
      rescue Psych::Exception
        nil
      end.to_h
      records.each_value do |item|
        item["dependency_safe"] = item["kind"] == "ticket" && Array(item["dependencies"]).all? { |id| records[id] && records[id]["state"] == "done" }
      end
      records
    end

    private

    def advance_ticket!(ticket_id, state:, run_id:, created_at:, reason:, merged_pull_request: nil)
      directory = ticket_directory(ticket_id)
      manifest_path = directory.join("manifest.yml")
      manifest = YAML.safe_load(File.read(manifest_path), aliases: false)
      previous_version = manifest.fetch("current_version")
      previous_path = directory.join(format("v%03d.md", previous_version))
      content = File.binread(previous_path).gsub("\r\n", "\n")
      match = content.match(/\A---\n(.*?)\n---\n/m)
      raise ValidationError, "#{ticket_id} current version has invalid front matter" unless match

      metadata = YAML.safe_load(match[1], aliases: false)
      version = previous_version + 1
      metadata.merge!(
        "version" => version,
        "author" => "product_factory_ci",
        "run_id" => run_id,
        "created_at" => created_at,
        "previous_version" => previous_version,
        "reason" => reason,
        "state" => state
      )
      next_path = directory.join(format("v%03d.md", version))
      body = content[match.end(0)..]
      File.write(next_path, "---\n#{YAML.dump(metadata).sub(/\A---\n/, "")}---\n#{body}")

      manifest.merge!(
        "current_version" => version,
        "state" => state,
        "content_sha256" => Digest::SHA256.hexdigest(File.binread(next_path).gsub("\r\n", "\n"))
      )
      manifest["merged_pull_request"] = merged_pull_request if merged_pull_request
      File.write(manifest_path, YAML.dump(manifest))
      append_changelog!(directory, ticket_id: ticket_id, version: version, run_id: run_id,
        created_at: created_at, reason: reason)
    end

    def append_changelog!(directory, ticket_id:, version:, run_id:, created_at:, reason:)
      path = idea_changelog(directory)
      FileUtils.mkdir_p(path.dirname)
      existing = path.file? ? File.read(path) : "# #{path.dirname.basename} changelog\n"
      existing = "#{existing.rstrip}\n" unless existing.empty?
      date = Time.iso8601(created_at).utc.strftime("%Y-%m-%d")
      File.write(path, "#{existing}- #{date} — `#{ticket_id}` v#{format("%03d", version)} — `#{run_id}` — #{reason}\n")
    end

    def idea_changelog(directory)
      parts = directory.relative_path_from(@root).each_filename.to_a
      raise ValidationError, "ticket artifact is outside an IDEA" unless parts[0] == "ideas" && parts[1]

      @root.join("ideas", parts[1], "changelog.md")
    end

    def ticket_directory(ticket_id)
      matches = @root.glob("ideas/**/tickets/**/manifest.yml").select do |path|
        YAML.safe_load(File.read(path), aliases: false)["id"] == ticket_id
      rescue Psych::Exception
        false
      end
      raise ValidationError, "#{ticket_id} does not map to exactly one ticket artifact" unless matches.one?

      matches.first.dirname
    end

    def enrich_ticket_projection!(item, manifest_path)
      current = manifest_path.dirname.join(format("v%03d.md", item["current_version"]))
      content = current.file? ? File.binread(current).gsub("\r\n", "\n") : ""
      metadata_match = content.match(/\A---\n(.*?)\n---\n/m)
      metadata = metadata_match ? YAML.safe_load(metadata_match[1], aliases: false) || {} : {}
      body = metadata_match ? content[metadata_match.end(0)..].to_s.strip : content.strip
      heading = body.lines.find { |line| line.match?(/\A#\s+/) }.to_s.sub(/\A#\s+/, "").strip
      parts = manifest_path.each_filename.to_a
      item["title"] = heading unless heading.empty?
      item["body"] = body
      item["idea_id"] = parts.find { |part| part.match?(/\AIDEA-\d{3,}(?:-|$)/) }&.match(/\AIDEA-\d{3,}/)&.to_s
      item["epic_id"] = parts.find { |part| part.match?(/\AEPIC-\d{3,}(?:-|$)/) }&.match(/\AEPIC-\d{3,}/)&.to_s
      item["factory_run"] = metadata["run_id"]
    rescue Psych::Exception
      nil
    end

    def successful_snapshot(phase)
      records = @root.join("factory-log").glob("*-finished.yml").filter_map do |path|
        YAML.safe_load(File.read(path), aliases: false)
      rescue Psych::Exception
        nil
      end
      successful = records.select { |record| record.is_a?(Hash) && record["phase"] == phase && record["status"] == "success" && record["source_snapshot"].is_a?(Hash) }
      successful.max_by { |record| record["finished_at"].to_s }&.fetch("source_snapshot")
    end
  end

  class Run
    attr_reader :id

    def self.start(root:, phase:, source_ids:)
      root = Pathname(root)
      id = "RUN-#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}-#{SecureRandom.hex(3)}"
      record = {
        "run_id" => id, "phase" => phase, "skill" => phase, "started_at" => Time.now.utc.iso8601,
        "finished_at" => nil, "source_ids" => source_ids, "source_snapshot" => Repository.new(root: root).snapshot,
        "output_ids" => [], "status" => "started", "external_changes" => [], "error" => nil, "next_action" => nil
      }
      FileUtils.mkdir_p(root.join("factory-log"))
      path = root.join("factory-log", "#{id}-started.yml")
      File.open(path, "wx") { |file| file.write(YAML.dump(record)) }
    rescue Errno::EEXIST
      raise ValidationError, "run record already exists: #{path.basename}"
    else
      new(path: path, id: id)
    end

    def initialize(path:, id:)
      @path = Pathname(path)
      @id = id
    end

    def self.move!(source_root:, destination_root:, id:)
      source = Pathname(source_root).join("factory-log", "#{id}-started.yml")
      source_finished = source.dirname.join("#{id}-finished.yml")
      destination_directory = Pathname(destination_root).join("factory-log")
      destination = destination_directory.join(source.basename)
      finished = destination_directory.join("#{id}-finished.yml")
      raise ValidationError, "run #{id} is already finished" if source_finished.exist? || finished.exist?
      return new(path: destination, id: id) if !source.exist? && destination.file?
      raise ValidationError, "unknown run #{id}" unless source.file?

      FileUtils.mkdir_p(destination_directory)
      content = File.binread(source)
      if destination.exist?
        raise ValidationError, "run #{id} destination differs from source" unless File.binread(destination) == content
      else
        File.open(destination, "wx") { |file| file.write(content) }
      end
      raise ValidationError, "run #{id} move verification failed" unless File.binread(destination) == content

      File.delete(source)
      new(path: destination, id: id)
    rescue Errno::EEXIST
      raise ValidationError, "run #{id} already exists at destination"
    end

    def finish!(status:, output_ids:, external_changes: [], error: nil)
      record = YAML.safe_load(File.read(@path), aliases: false)
      record["finished_at"] = Time.now.utc.iso8601
      record["status"] = status
      record["output_ids"] = output_ids
      record["external_changes"] = external_changes
      record["error"] = error
      record["next_action"] = status == "success" ? "none" : "review run"
      finished_path = @path.dirname.join("#{@id}-finished.yml")
      raise ValidationError, "run #{@id} is already finished" if finished_path.exist?

      write_record(finished_path, record)
      nil
    end

    private

    def write_record(path, record)
      File.open(path, "wx") { |file| file.write(YAML.dump(record)) }
    rescue Errno::EEXIST
      raise ValidationError, "run record already exists: #{path.basename}"
    end
  end

  class ClaimRegistry
    def initialize(git_common_dir:) = @root = Pathname(git_common_dir).join("product-factory")

    def claim!(ticket_id:, run_id:)
      validate_ticket!(ticket_id)
      with_lock do
        claim = read_claim(ticket_id)
        raise ClaimConflict, "#{ticket_id} is claimed by #{claim["run_id"]}" if claim && claim["run_id"] != run_id

        File.write(claim_path(ticket_id), YAML.dump("ticket_id" => ticket_id, "run_id" => run_id)) unless claim
      end
      nil
    end

    def release!(ticket_id:, run_id:)
      validate_ticket!(ticket_id)
      with_lock do
        claim = read_claim(ticket_id)
        raise ClaimConflict, "#{ticket_id} is claimed by #{claim["run_id"]}" if claim && claim["run_id"] != run_id

        File.delete(claim_path(ticket_id)) if claim
      end
      nil
    end

    private

    def with_lock
      FileUtils.mkdir_p(@root)
      File.open(@root.join(".lock"), "w") do |lock|
        lock.flock(File::LOCK_EX)
        yield
      ensure
        lock.flock(File::LOCK_UN) if lock
      end
    end

    def read_claim(ticket_id)
      path = claim_path(ticket_id)
      path.file? ? YAML.safe_load(File.read(path), aliases: false) : nil
    end

    def claim_path(ticket_id) = @root.join("#{ticket_id}.yml")

    def validate_ticket!(ticket_id)
      raise ArgumentError, "invalid ticket ID" unless ticket_id.match?(/\ATICKET-\d{3,}\z/)
    end
  end
end
