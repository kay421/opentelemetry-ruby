# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'

module OpenTelemetry
  module Instrumentation
    module Sequel
      module Patches
        # Module to prepend to Sequel::Dataset for instrumentation
        module Dataset
          def execute(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_ddl(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_dui(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_insert(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          private

          def tracer
            Sequel::Instrumentation.instance.tracer
          end

          def config
            Sequel::Instrumentation.instance.config
          end

          def trace_execute(super_method, sql, options, &block)
            opts = Utils.parse_opts(sql, options, db.opts, self)
            response = nil

            span_name, attrs = span_attrs(:execute, *args)
            tracer.in_span(span_name, attributes: attrs, kind: :client) do
              response = super_method.call(sql, options, &block)
            end
            response
          end
        end
      end
    end
  end
end
