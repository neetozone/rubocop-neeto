# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # `html_safe`, `raw` and `safe_concat` mark a string as already safe, so
      # Rails prints it without escaping. Calling them on a dynamic value
      # (interpolation, a method result, a variable) turns escaping off for
      # whatever that value holds, which lets user input inject markup. Build
      # markup with `tag`, `content_tag`, `link_to`, `mail_to` or `safe_join`
      # instead. A call that has been reviewed can be kept by adding
      # `# neeto:html-safe-reviewed <reason>` on or above it.
      #
      # @example HtmlSafeOnDynamicString: true (opt-in)
      #   # bad
      #   "<b>#{booking.name}</b>".html_safe
      #
      #   # bad
      #   raw(message.body)
      #
      #   # good
      #   tag.b(booking.name)
      #
      #   # good
      #   "<br>".html_safe
      #
      #   # good
      #   # neeto:html-safe-reviewed admin-authored rich text
      #   meeting.cancellation_policy.html_safe
      #
      class HtmlSafeOnDynamicString < Base
        MSG = "Do not call `%<method>s` on a dynamic value. Build the markup with `tag`, `content_tag`, " \
              "`link_to`, `mail_to` or `safe_join`, or add `# neeto:html-safe-reviewed <reason>` if the value " \
              "is known to be safe."

        REVIEWED_ANNOTATION = /#\s*neeto:html-safe-reviewed\s+\S/

        RESTRICT_ON_SEND = %i[html_safe raw safe_concat].freeze

        def on_send(node)
          value = trusted_value(node)
          return if value.nil? || static_string?(value) || reviewed?(node)

          add_offense(node.loc.selector, message: format(MSG, method: node.method_name))
        end
        alias on_csend on_send

        private

          def trusted_value(node)
            case node.method_name
            when :html_safe
              node.receiver if node.arguments.none?
            when :raw
              node.first_argument if node.receiver.nil? && node.arguments.one?
            when :safe_concat
              node.first_argument if node.arguments.one?
            end
          end

          def static_string?(node)
            node.str_type? || (node.dstr_type? && node.children.all? { |child| static_string?(child) })
          end

          def reviewed?(node)
            lines = (node.first_line - 1)..node.last_line

            processed_source.comments.any? do |comment|
              lines.cover?(comment.loc.line) && REVIEWED_ANNOTATION.match?(comment.text)
            end
          end
      end
    end
  end
end
