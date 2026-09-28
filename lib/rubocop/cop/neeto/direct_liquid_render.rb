# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      class DirectLiquidRender < Base
        MSG = "Do not use `Liquid::Template.%<method>s` directly. Render Liquid through the shared renderer, " \
              "e.g. `NeetoLiquid.render(template, variables, format: :html)`, so every render declares its " \
              "output format."

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
