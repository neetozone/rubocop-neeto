# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # `Liquid::Template#render` does not escape its output, so every variable
      # reaches the page or email as-is. Render Liquid through the shared
      # renderer, which escapes every output and requires an explicit format.
      # Code that only checks a template's syntax uses `validate!`, which raises
      # `Liquid::SyntaxError` like `Liquid::Template.parse` does.
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
      #   # bad
      #   Liquid::Template.parse(metadata["body"])
      #
      #   # good
      #   NeetoCommonsBackend::LiquidRenderer.validate!(metadata["body"])
      #
      class DirectLiquidRender < Base
        MSG = "Do not use `Liquid::Template.%<method>s` directly. Render with " \
              "`NeetoCommonsBackend::LiquidRenderer.render(template, variables, format: :html)`, which escapes " \
              "every output, or check syntax with `NeetoCommonsBackend::LiquidRenderer.validate!(template)`."

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
