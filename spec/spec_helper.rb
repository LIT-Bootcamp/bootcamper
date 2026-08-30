require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  skip "/spec/"
  minimum_coverage line: 99, branch: 84 if ENV["CI"]
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.order = :random
  Kernel.srand config.seed
end
