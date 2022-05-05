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

            # Tracing.trace(Ext::SPAN_QUERY) do |span|
            #   span.resource = opts[:query]
            #   span.span_type = Tracing::Metadata::Ext::SQL::TYPE
            #   Utils.set_common_tags(span, self)
            #   span.set_tag(Ext::TAG_DB_VENDOR, adapter_name)
            #   response = super(sql, options)
            # end
          end

          Sequel::Constants::EXEC_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name, attrs = span_attrs(:query, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                super(*args)
              end
            end
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

          # Rubocop is complaining about 19.31/18 for Metrics/AbcSize.
          # But, getting that metric in line would force us over the
          # module size limit! We can't win here unless we want to start
          # abstracting things into a million pieces.
          def span_attrs(kind, *args) # rubocop:disable Metrics/AbcSize
            operation = extract_operation(args[0])
            sql = obfuscate_sql(args[0]).to_s

            attrs = { 'db.operation' => validated_operation(operation), 'db.postgresql.prepared_statement_name' => statement_name }
            attrs['db.statement'] = sql unless config[:db_statement] == :omit
            attrs.reject! { |_, v| v.nil? }

            [span_name(operation), client_attributes.merge(attrs)]
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-sequel/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
          end

          def span_name(operation)
            [validated_operation(operation), database_name].compact.join(' ')
          end

          def validated_operation(operation)
            operation if Sequel::Constants::SQL_COMMANDS.include?(operation)
          end

          def obfuscate_sql(sql)
            return sql unless config[:db_statement] == :obfuscate

            # Borrowed from opentelemetry-instrumentation-mysql2
            return 'SQL query too large to remove sensitive data ...' if sql.size > 2000

            # From:
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscator.rb
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb
            obfuscated = sql.gsub(generated_postgres_regex, '?')
            obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if Sequel::Constants::UNMATCHED_PAIRS_REGEX.match(obfuscated)

            obfuscated
          end

          def generated_postgres_regex
            @generated_postgres_regex ||= Regexp.union(Sequel::Constants::POSTGRES_COMPONENTS.map { |component| Sequel::Constants::COMPONENTS_REGEX_MAP[component] })
          end

          def database_name
            conninfo_hash[:dbname]&.to_s
          end

          def client_attributes
            attributes = {
              'db.system' => 'postgresql',
              'db.user' => conninfo_hash[:user]&.to_s,
              'db.name' => database_name,
              'net.peer.name' => conninfo_hash[:host]&.to_s
            }
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]

            attributes.merge(transport_attrs).reject { |_, v| v.nil? }
          end

          def transport_attrs
            if conninfo_hash[:host]&.start_with?('/')
              { 'net.transport' => 'Unix' }
            else
              {
                'net.transport' => 'IP.TCP',
                'net.peer.ip' => conninfo_hash[:hostaddr]&.to_s,
                'net.peer.port' => conninfo_hash[:port]&.to_s
              }
            end
          end
        end
      end
    end
  end
end
