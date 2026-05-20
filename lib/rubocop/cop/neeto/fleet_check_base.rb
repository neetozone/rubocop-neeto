# frozen_string_literal: true

require_relative "../../neeto/fleet_todo"

module RuboCop
  module Cop
    module Neeto
      # Base class for "fleet" cops — cops that enforce a contract owned by a
      # Neeto nano (e.g. "outbound webhooks must go through
      # `NeetoWebhooksEngine::DeliverService`"). Each fleet cop is paired with
      # a per-app `fleet_todo.yml` that records pre-existing bypasses so they
      # can be grandfathered while new offenses fail CI.
      #
      # Subclasses use `fleet_offense(node, message:)` instead of `add_offense`.
      # The base class handles:
      #
      # * Locating the app's project root (nearest ancestor with a Gemfile).
      # * Observing every match into the app's `FleetTodo` instance.
      # * Suppressing offenses that fall within the allowlisted count.
      # * Honouring `NEETO_FLEET_RECORD=1` (record mode) — never adds offenses,
      #   leaving the formatter / rake task to dump the recorded counts.
      #
      class FleetCheckBase < Base
        def on_new_investigation
          super
          @per_file_occurrence_index = 0
        end

        private

          def fleet_offense(node, message:)
            file = processed_source.file_path.to_s
            todo = fleet_todo_for(file)
            return add_offense(node, message:) unless todo

            todo.observe!(cop_name, file)
            index = @per_file_occurrence_index
            @per_file_occurrence_index += 1

            return if record_mode?
            return if todo.listed?(cop_name, file, index)

            add_offense(node, message:)
          end

          def record_mode?
            ENV["NEETO_FLEET_RECORD"] == "1"
          end

          def fleet_todo_for(file)
            root = project_root_for(file)
            return nil unless root

            RuboCop::Neeto::FleetTodo.for(root)
          end

          def project_root_for(file)
            path = Pathname.new(file).expand_path
            path.ascend do |dir|
              return dir if dir.join("Gemfile").exist? || dir.join("config.ru").exist?
            end
            nil
          end
      end
    end
  end
end
