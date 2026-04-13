if ENV.fetch("RAILS_ENV", "test") == "test"
  require "simplecov"
  require "fileutils"

  SimpleCov.command_name(ENV.fetch("SIMPLECOV_COMMAND_NAME", "RSpec"))

  %w[coverage/simplecov_report coverage/all_files_simplecov_report coverage/rspec].each do |stale_dir|
    FileUtils.rm_rf(stale_dir)
  end

  SimpleCov.start "rails" do
    enable_coverage :branch
    coverage_dir "coverage"
    add_filter "/bin/"
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/features/"
    add_filter "/spec/"
    add_filter "/test/"
  end
end
