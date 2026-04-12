if ENV.fetch("RAILS_ENV", "test") == "test"
  require "simplecov"

  SimpleCov.command_name(ENV.fetch("SIMPLECOV_COMMAND_NAME", "RSpec"))

  SimpleCov.start "rails" do
    enable_coverage :branch
    coverage_dir "coverage/all_files_simplecov_report"
    add_filter "/bin/"
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/features/"
    add_filter "/spec/"
    add_filter "/test/"
  end
end
