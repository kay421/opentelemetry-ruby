# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'

module OpenTelemetry
  module Instrumentation
    module Sequel
      module Patches
        # Module to prepend to Sequel::Database for instrumentation
        module Database

          def run(sql, options = ::Sequel::OPTS)
            opts = parse_opts(sql, options)
            response = nil
            span_name, attrs = span_attrs(:execute, *args)
            tracer.in_span(span_name, attributes: attrs, kind: :client) do
              response = super(sql, options)
            end
            response
          end

          private

          def tracer
            Sequel::Instrumentation.instance.tracer
          end

          def config
            Sequel::Instrumentation.instance.config
          end

          def parse_opts(sql, opts)
            db_opts = if ::Sequel::VERSION < '3.41.0' && self.class.to_s !~ /Dataset$/
                        @opts
                      elsif instance_variable_defined?(:@pool) && @pool
                        @pool.db.opts
                      end
            sql = sql.is_a?(::Sequel::SQL::Expression) ? literal(sql) : sql.to_s

            Utils.parse_opts(sql, opts, db_opts)
          end

          def adapter_name
            Utils.adapter_name(db)
          end

          # Rubocop is complaining about 19.31/18 for Metrics/AbcSize.
          # But, getting that metric in line would force us over the
          # module size limit! We can't win here unless we want to start
          # abstracting things into a million pieces.
          def span_attrs(kind, *args) # rubocop:disable Metrics/AbcSize
            operation = extract_operation(args[0])
            sql = obfuscate_sql(args[0]).to_s

            attrs = { 
              'db.operation' => validated_operation(operation), 
              'db.prepared_statement_name' => statement_name 
            }
            attrs['db.statement'] = sql unless config[:db_statement] == :omit
            attrs.reject! { |_, v| v.nil? }

            [span_name(operation), client_attributes.merge(attrs)]
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-sequel/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
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

          def generated_postgres_regex
            @generated_postgres_regex ||= Regexp.union(Sequel::Constants::POSTGRES_COMPONENTS.map { |component| Sequel::Constants::COMPONENTS_REGEX_MAP[component] })
          end

          def database_name
            conninfo_hash[:dbname]&.to_s
          end

          def client_attributes
            attributes = {

            }
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]

            attributes.reject { |_, v| v.nil? }
          end
        end
      end
    end
  end
end
