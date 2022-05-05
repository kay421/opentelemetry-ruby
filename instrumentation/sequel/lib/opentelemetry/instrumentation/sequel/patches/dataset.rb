# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'
require_relative '../utils'

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

            span_name, attrs = span_attrs(super_method, sql, options, &block)
            tracer.in_span(span_name, attributes: attrs, kind: :client) do
              response = super_method.call(sql, options, &block)
            end
            response
          end

          def span_attrs(super_method, sql, options, &block)
            operation = extract_operation(sql)
            sql = obfuscate_sql(sql).to_s   
            statement_name = nil

            attrs = { 
              'peer.service' => adapter_name,
              'db.operation' => validated_operation(operation), 
              'db.prepared_statement_name' => statement_name, 
            }
            attrs['db.statement'] = sql unless config[:db_statement] == :omit
            attrs.reject! { |_, v| v.nil? }

            [span_name(operation), client_attributes.merge(attrs)]
          end

          def adapter_name
            Utils.adapter_name(db)
          end

          def span_name(operation)
            validated_operation(operation)
          end

          def validated_operation(operation)
            operation if Sequel::Constants::SQL_COMMANDS.include?(operation)
          end

          def obfuscate_sql(sql)
            # todo obfuscate
            # return sql unless config[:db_statement] == :obfuscate
            return sql
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-pg/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
          end

          def client_attributes
            attributes = {}
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]

            attributes.reject { |_, v| v.nil? }
          end

        end
      end
    end
  end
end
