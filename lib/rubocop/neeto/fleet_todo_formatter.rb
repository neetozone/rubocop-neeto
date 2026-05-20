# frozen_string_literal: true

require "rubocop"
require_relative "fleet_todo"

module RuboCop
  module Neeto
    # Formatter that closes the loop on a `Neeto/*` fleet cop run. RuboCop
    # invokes `finished(...)` exactly once, after all files have been inspected
    # — that's the only hook where we know every cop has observed every match.
    #
    # In record mode (`NEETO_FLEET_RECORD=1`) we rewrite `fleet_todo.yml` from
    # the observed counts. In check mode we print a "stale entry" report for
    # every file whose observed count fell below the recorded ceiling — those
    # are bypasses that have already been fixed in code but still listed in
    # the todo file, and they should be removed so the file ratchets down.
    #
    # Use via:
    #
    #     bundle exec rubocop --only Neeto/WebhooksBypass \
    #       --format RuboCop::Neeto::FleetTodoFormatter
    #
    # Stale entries do not in themselves fail the rubocop run (rubocop's exit
    # code is determined by offenses, not formatter output). The companion
    # rake task `neeto:fleet:check` provides the fail-on-stale behavior.
    #
    class FleetTodoFormatter < RuboCop::Formatter::BaseFormatter
      def finished(_inspected_files)
        FleetTodo.instance_variable_get(:@instances).to_h.each_value do |todo|
          if record_mode?
            todo.dump_recording!
            output.puts "[fleet_todo] Recorded #{todo.path}"
          else
            report_stale(todo)
          end
        end
      end

      private

        def record_mode?
          ENV["NEETO_FLEET_RECORD"] == "1"
        end

        def report_stale(todo)
          stale = todo.stale_entries
          return if stale.empty?

          output.puts "[fleet_todo] Stale entries in #{todo.path}:"
          stale.each do |cop, files|
            files.each do |file, counts|
              output.puts(
                format("  - %<cop>s %<file>s: observed=%<observed>d allowed=%<allowed>d",
                  cop:, file:, observed: counts[:observed], allowed: counts[:allowed]))
            end
          end
          output.puts "Re-run with NEETO_FLEET_RECORD=1 to prune."
        end
    end
  end
end
