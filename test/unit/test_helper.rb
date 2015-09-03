if ENV["CODECLIMATE_REPO_TOKEN"]
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
else
  require "simplecov"
  SimpleCov.start
end

require "test/unit"

module RogerStyleGuide
  # Container for all tests
  module Test
  end
end

# Load fixture
def fixture(path)
  File.read(File.dirname(__FILE__) + "/../fixtures/#{path}")
end
