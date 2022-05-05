# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sequel
      module Utils
        class << self
          def parse_opts(sql, opts, dataset = nil)
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
