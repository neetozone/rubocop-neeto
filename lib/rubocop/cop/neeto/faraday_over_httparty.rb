# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # HTTParty has been removed from all Neeto applications in favor of
      # Faraday, which is already available. This cop flags any attempt to add
      # the `httparty` gem to a Gemfile.
      #
      # @example FaradayOverHttparty: true (default)
      #   # Disallows adding the `httparty` gem.
      #
      #   # bad
      #   gem "httparty"
      #
      #   # good
      #   gem "faraday"
      #
      class FaradayOverHttparty < Base
        MSG = "Do not add the `httparty` gem. Use `faraday` instead, which is " \
          "already available in the application. See " \
          "https://github.com/neetozone/neeto-engineering/issues/1862 for more details."

        RESTRICT_ON_SEND = %i[gem].freeze

        def_node_matcher :httparty_gem?, <<~PATTERN
          (send nil? :gem (str $_) ...)
        PATTERN

        def on_send(node)
          httparty_gem?(node) do |gem_name|
            add_offense(node) if gem_name.casecmp?("httparty")
          end
        end
      end
    end
  end
end
