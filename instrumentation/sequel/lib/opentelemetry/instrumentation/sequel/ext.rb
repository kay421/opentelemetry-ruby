# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sequel
      module Ext
        ENV_ENABLED = 'OPENTELEMETRY_SEQUEL_ENABLED'.freeze
        ENV_ANALYTICS_ENABLED = 'OPENTELEMETRY_SEQUEL_ANALYTICS_ENABLED'.freeze
        ENV_ANALYTICS_SAMPLE_RATE = 'OPENTELEMETRY_SEQUEL_ANALYTICS_SAMPLE_RATE'.freeze
        SPAN_QUERY = 'sequel.query'.freeze
        TAG_DB_VENDOR = 'sequel.db.vendor'.freeze
        TAG_PREPARED_NAME = 'sequel.prepared.name'.freeze
        TAG_COMPONENT = 'sequel'.freeze
        TAG_OPERATION_QUERY = 'query'.freeze        
      end
    end
  end
end
