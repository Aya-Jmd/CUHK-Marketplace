ENV["SIMPLECOV_COMMAND_NAME"] ||= "RSpec"
require_relative "../config/simplecov"

require "regexp_parser/error"

class Regexp
  module Syntax
    class SyntaxError < Regexp::Parser::Error; end unless const_defined?(:SyntaxError, false)
  end
end

require "regexp_parser/syntax/version_lookup"

module Regexp::Syntax
  class << self
    def version_class(version)
      return Regexp::Syntax::Any if ["*", "any"].include?(version.to_s)

      version =~ VERSION_REGEXP || raise(InvalidVersionNameError, version)

      version_const_name = "V#{version.to_s.scan(/\d+/).join('_')}"
      const_get(version_const_name)
    rescue NameError
      fallback_version_class(version_const_name) || raise(UnknownSyntaxNameError, version)
    end

    def specified_versions
      constants.select { |const_name| VERSION_CONST_REGEXP.match?(const_name.to_s) }
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
