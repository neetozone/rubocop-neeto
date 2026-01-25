# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # Rails had `secrets.yml` which provided a single source of truth for all
      # environment variables and their fallback values. Rails deprecated this in
      # favor of encrypted credentials, so we created Secvault
      # (https://github.com/neetozone/secvault) to maintain centralized configuration.
      # Direct usage of `ENV` bypasses this system, making it harder to track what
      # environment variables are being used and their defaults. This cop enforces
      # that all environment variable access goes through `Secvault.secrets`.
      #
      # @example DirectEnvAccess: true (default)
      #   # Enforces the usage of `Secvault.secrets` over direct `ENV` access.
      #
      #   # bad
      #   # app/services/payment_service.rb
      #   api_key = ENV['STRIPE_API_KEY']
      #
      #   # bad
      #   # app/models/user.rb
      #   default_timezone = ENV['DEFAULT_TIMEZONE'] || 'UTC'
      #
      #   # good
      #   # app/services/payment_service.rb
      #   api_key = Secvault.secrets.stripe_api_key
      #
      #   # good
      #   # app/models/user.rb
      #   default_timezone = Secvault.secrets.default_timezone
      #
      #   # good (ENV access in config directory is permitted)
      #   # config/environments/production.rb
      #   config.log_level = ENV.fetch('LOG_LEVEL', 'info')
      #
      class DirectEnvAccess < Base
        MSG = "Do not use ENV directly. " \
        "Use Secvault.secrets to maintain a single source of truth for configuration."

        def_node_matcher :env_access?, <<~PATTERN
          (send (const {nil? cbase} :ENV) _ ...)
        PATTERN

        def on_send(node)
          return unless env_access?(node)

          add_offense(node)
        end
      end
    end
  end
end
