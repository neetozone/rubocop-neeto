# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # `config/secrets.yml` provides a single source of truth for all
      # environment variables and their fallback values, loaded via Rails'
      # built-in `config_for`. Direct usage of `ENV` bypasses this system,
      # making it harder to track what environment variables are being used
      # and their defaults. This cop enforces that all environment variable
      # access goes through `Rails.application.secrets`.
      #
      # @example DirectEnvAccess: true (default)
      #   # Enforces the usage of `Rails.application.secrets` over direct `ENV` access.
      #
      #   # bad
      #   api_key = ENV['STRIPE_API_KEY']
      #
      #   # bad
      #   default_timezone = ENV['DEFAULT_TIMEZONE'] || 'UTC'
      #
      #   # good
      #   api_key = Rails.application.secrets.stripe_api_key
      #
      #   # good
      #   default_timezone = Rails.application.secrets.default_timezone
      #
      #   # good (ENV access is permitted in directories other than the app directory)
      #   config.log_level = ENV.fetch('LOG_LEVEL', 'info')
      #
      class DirectEnvAccess < Base
        MSG = "Do not use ENV directly. " \
              "Use Rails.application.secrets to maintain a single source of truth for configuration."

        def_node_matcher :env_access?, <<~PATTERN
          (const {nil? cbase} :ENV)
        PATTERN

        def on_const(node)
          return unless env_access?(node)

          add_offense(node)
        end
      end
    end
  end
end
