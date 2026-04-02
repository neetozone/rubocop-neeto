# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # The legacy `NeetoCommonsBackend::BaseJobs::*` base classes have been
      # replaced with latency-based job classes such as
      # `LatencyBasedJobs::Within5Seconds`, `LatencyBasedJobs::Within1Minute`,
      # `LatencyBasedJobs::Within5Minutes`, and `LatencyBasedJobs::Within1Hour`.
      # This cop prevents new jobs from inheriting directly from the legacy
      # Neeto Commons base classes.
      #
      # @example LegacyJobInheritance: true (default)
      #   # bad
      #   class ExportJob < NeetoCommonsBackend::BaseJobs::Default
      #   end
      #
      #   # bad
      #   class SyncWebhookJob < NeetoCommonsBackend::BaseJobs::Urgent
      #   end
      #
      #   # good
      #   class ExportJob < LatencyBasedJobs::Within5Minutes
      #   end
      #
      #   # good
      #   class SyncWebhookJob < LatencyBasedJobs::Within5Seconds
      #   end
      #
      #   # good
      #   # Defining the latency classes themselves
      #   module LatencyBasedJobs
      #     class Within5Seconds < NeetoCommonsBackend::BaseJobs::Base
      #     end
      #   end
      #
      class LegacyJobInheritance < Base
        LEGACY_SUPERCLASSES = {
          "NeetoCommonsBackend::BaseJobs::Urgent" => "Use `LatencyBasedJobs::Within5Seconds` instead.",
          "NeetoCommonsBackend::BaseJobs::Auth" => "Use `LatencyBasedJobs::Within1Minute` instead.",
          "NeetoCommonsBackend::BaseJobs::Default" => "Use `LatencyBasedJobs::Within1Minute` or `LatencyBasedJobs::Within5Minutes` based on the job's SLA.",
          "NeetoCommonsBackend::BaseJobs::Low" => "Use `LatencyBasedJobs::Within1Hour` instead.",
          "NeetoCommonsBackend::BaseJobs::Base" => "Use a latency-based job base class instead, for example `LatencyBasedJobs::Within5Seconds`, `LatencyBasedJobs::Within1Minute`, `LatencyBasedJobs::Within5Minutes`, or `LatencyBasedJobs::Within1Hour`."
        }.freeze

        MSG = "Do not inherit jobs directly from `%<superclass>s`. %<replacement>s"

        def on_class(node)
          return if allowed_file_path?

          superclass = node.parent_class
          return unless superclass&.const_type?

          superclass_name = superclass.const_name
          replacement = LEGACY_SUPERCLASSES[superclass_name]
          return unless replacement

          add_offense(superclass, message: format(MSG, superclass: superclass_name, replacement:))
        end

        private

          def allowed_file_path?
            file_path = processed_source.file_path.to_s

            file_path.end_with?("app/jobs/concerns/latency_based_jobs.rb") ||
              file_path.match?(%r{(?:\A|/)app/jobs/neeto_commons_backend/base_jobs/})
          end
      end
    end
  end
end
