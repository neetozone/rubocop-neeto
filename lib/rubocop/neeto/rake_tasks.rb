# frozen_string_literal: true

require "rake"
require "rubocop"
require_relative "fleet_todo"
require_relative "fleet_todo_formatter"

module RuboCop
  module Neeto
    # Apps wire fleet-todo rake tasks by adding the following to their
    # `Rakefile`:
    #
    #     require "rubocop/neeto/rake_tasks"
    #     RuboCop::Neeto::RakeTasks.install
    #
    # This exposes:
    #
    #   * `rake neeto:fleet:check`        — fails if there are unlisted
    #                                       bypasses OR stale entries.
    #   * `rake neeto:fleet:update_todo`  — rewrites `fleet_todo.yml` from
    #                                       the current code (record mode).
    #
    # Both tasks delegate to RuboCop's CLI rather than reimplementing it.
    #
    module RakeTasks
      module_function

      def install
        namespace :neeto do
          namespace :fleet do
            desc "Fail on new bypasses OR stale fleet_todo.yml entries."
            task :check do
              FleetTodo.reset!
              status = run_rubocop(record: false)
              report = stale_report
              if !report.empty?
                warn(report)
                exit(1)
              end
              exit(status)
            end

            desc "Rewrite fleet_todo.yml from the current code."
            task :update_todo do
              FleetTodo.reset!
              status = run_rubocop(record: true)
              exit(status)
            end
          end
        end
      end

      def run_rubocop(record:)
        env_before = ENV["NEETO_FLEET_RECORD"]
        ENV["NEETO_FLEET_RECORD"] = "1" if record
        args = [
          "--only", neeto_fleet_cops.join(","),
          "--format", "RuboCop::Neeto::FleetTodoFormatter",
          "--require", "rubocop-neeto"
        ]
        RuboCop::CLI.new.run(args)
      ensure
        ENV["NEETO_FLEET_RECORD"] = env_before
      end

      def neeto_fleet_cops
        registry = RuboCop::Cop::Registry.global
        registry.cops.select { |c| c < RuboCop::Cop::Neeto::FleetCheckBase }.map(&:cop_name)
      end

      def stale_report
        lines = []
        FleetTodo.instance_variable_get(:@instances).to_h.each_value do |todo|
          stale = todo.stale_entries
          next if stale.empty?

          lines << "[fleet_todo] Stale entries in #{todo.path}:"
          stale.each do |cop, files|
            files.each do |file, counts|
              lines << format("  - %<cop>s %<file>s: observed=%<observed>d allowed=%<allowed>d",
                cop:, file:, observed: counts[:observed], allowed: counts[:allowed])
            end
          end
        end
        lines.join("\n")
      end
    end
  end
end
