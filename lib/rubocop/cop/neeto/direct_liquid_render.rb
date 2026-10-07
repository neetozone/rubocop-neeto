# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # `Liquid::Template#render` does not escape its output, so every variable
      # reaches the page or email as-is. Render Liquid through the shared
      # renderer, which escapes every output and requires an explicit format.
      #
      # @example DirectLiquidRender: true (opt-in)
      #   # bad
      #   Liquid::Template.parse(template.body).render(variables)
      #
      #   # good
      #   NeetoCommonsBackend::LiquidRenderer.render(template.body, variables, format: :html)
      #
      #   # good
      #   NeetoCommonsBackend::LiquidRenderer.render(template.subject, variables, format: :text)
      #
      class DirectLiquidRender < Base
        MSG = "Do not use `Liquid::Template.%<method>s` directly. Render Liquid through " \
              "`NeetoCommonsBackend::LiquidRenderer.render(template, variables, format: :html)`, which escapes " \
              "every output and makes each render declare its format."

        RESTRICT_ON_SEND = %i[parse new].freeze

        def_node_matcher :liquid_template_build?, <<~PATTERN
          (send (const (const {nil? cbase} :Liquid) :Template) {:parse :new} ...)
        PATTERN

        def on_send(node)
          return unless liquid_template_build?(node)

          add_offense(node, message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
