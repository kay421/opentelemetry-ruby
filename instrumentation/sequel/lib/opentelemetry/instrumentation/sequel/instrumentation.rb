# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sequel
      # The Instrumentation class contains logic to detect and install the Pg instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('3.41.0')

        install do |config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::Sequel)
        end

        compatible do
          gem_version > Gem::Version.new(MINIMUM_VERSION)
        end

        option :db_statement, default: :include, validate: %I[omit include obfuscate]

        private

        def gem_version
          Gem::Version.new(::Sequel::VERSION)
        end

        def require_dependencies
          require_relative 'patches/connection'
        end

        def patch_client
          ::Sequel::Connection.prepend(Patches::Connection)
        end
      end
    end
  end
end
