# frozen_string_literal: true

require "rbconfig"
require "socket"

module Sys
  class Uname
    UnameStruct = Struct.new(:sysname, :nodename, :release, :version, :machine)

    def self.uname
      UnameStruct.new(sysname, nodename, release, version, machine)
    end

    def self.sysname
      RbConfig::CONFIG["target_os"].to_s
    end

    def self.nodename
      Socket.gethostname
    rescue StandardError
      "localhost"
    end

    def self.release
      RbConfig::CONFIG["host_os"].to_s
    end

    def self.version
      RbConfig::CONFIG["RUBY_PROGRAM_VERSION"].to_s
    end

    def self.machine
      RbConfig::CONFIG["host_cpu"].to_s
    end
  end
end
