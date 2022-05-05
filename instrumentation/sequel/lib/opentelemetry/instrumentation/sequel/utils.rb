# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'ext'

module OpenTelemetry
  module Instrumentation
    module Sequel
      module Utils
        class << self

          VENDOR_DEFAULT = 'defaultdb'.freeze
          VENDOR_POSTGRES = 'postgres'.freeze
          VENDOR_SQLITE = 'sqlite'.freeze

          def normalize_vendor(vendor)
            case vendor
            when nil
              VENDOR_DEFAULT
            when 'postgresql'
              VENDOR_POSTGRES
            when 'sqlite3'
              VENDOR_SQLITE
            else
              vendor
            end
          end          

          # Ruby database connector library
          #
          # e.g. adapter:mysql2 (database:mysql), adapter:jdbc (database:postgres)
          def adapter_name(database)
            scheme = database.adapter_scheme.to_s

            if scheme == 'jdbc'.freeze
              # The subtype is more important in this case,
              # otherwise all database adapters will be 'jdbc'.
              database_type(database)
            else
              normalize_vendor(scheme)
            end
          end

          # e.g. database:mysql (adapter:mysql2), database:postgres (adapter:jdbc)
          def database_type(database)
            normalize_vendor(database.database_type.to_s)
          end

          def parse_opts(sql, opts, db_opts, dataset = nil)
            # Prepared statements don't provide their sql query in the +sql+ parameter.
            if !sql.is_a?(String) && (dataset && dataset.respond_to?(:prepared_sql) &&
              (resolved_sql = dataset.prepared_sql))
              # The dataset contains the resolved SQL query and prepared statement name.
              prepared_name = dataset.prepared_statement_name
              sql = resolved_sql
            end

            {
              name: opts[:type],
              query: sql,
              prepared_name: prepared_name,
              database: db_opts[:database],
              host: db_opts[:host]
            }
          end         
        end
      end
    end
  end
end
