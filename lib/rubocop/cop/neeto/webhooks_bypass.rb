# frozen_string_literal: true

require_relative "fleet_check_base"

module RuboCop
  module Cop
    module Neeto
      # Apps that depend on `neeto-webhooks-engine` should fire user-configured
      # outbound webhooks through `NeetoWebhooksEngine::DeliverService` — that
      # service handles retries, signing, rate limiting, and observability
      # consistently across the fleet. Hand-rolled `Faraday.post` / `HTTParty.post`
      # bypasses each of those concerns.
      #
      # Scope: this cop only inspects files whose path looks webhook-related
      # (`*webhook*.rb`, or anything under a `webhooks?/` directory). That
      # heuristic keeps the cop from flagging legitimate raw-HTTP use elsewhere
      # (e.g. integrations with third-party APIs that aren't webhooks).
      #
      # Pre-existing bypasses can be allowlisted with:
      #
      #   NEETO_FLEET_RECORD=1 bundle exec rubocop --only Neeto/WebhooksBypass
      #
      # which writes counts into `fleet_todo.yml` at the app root.
      #
      # @example
      #   # bad — in app/services/messages/webhook_service.rb
      #   Faraday.post(endpoint.url, payload.to_json)
      #
      #   # good — in app/services/messages/webhook_service.rb
      #   NeetoWebhooksEngine::DeliverService
      #     .new(entity: organization, event_identifier:, body: payload.to_json)
      #     .process_later
      #
      class WebhooksBypass < FleetCheckBase
        MSG = "Outbound webhook bypass: use `NeetoWebhooksEngine::DeliverService` " \
              "instead of `%<receiver>s.%<method>s` for user-configured webhooks. " \
              "If this call is not a webhook, record it in `fleet_todo.yml` with " \
              "`NEETO_FLEET_RECORD=1 bundle exec rubocop --only Neeto/WebhooksBypass`."

        HTTP_LIBRARIES = %w[Faraday HTTParty RestClient].freeze
        HTTP_METHODS = %i[post put patch delete].freeze

        def_node_matcher :raw_http_call?, <<~PATTERN
          (send (const {nil? cbase} $_) ${:post :put :patch :delete} ...)
        PATTERN

        def on_send(node)
          return unless webhook_flavored_file?

          receiver, method_name = raw_http_call?(node)
          return unless receiver
          return unless HTTP_LIBRARIES.include?(receiver.to_s)
          return unless HTTP_METHODS.include?(method_name)

          fleet_offense(node, message: format(MSG, receiver:, method: method_name))
        end

        private

          def webhook_flavored_file?
            path = processed_source.file_path.to_s
            path.match?(%r{/[^/]*webhook[^/]*\.rb\z}) ||
              path.match?(%r{\A[^/]*webhook[^/]*\.rb\z}) ||
              path.match?(%r{/webhooks?/})
          end
      end
    end
  end
end
