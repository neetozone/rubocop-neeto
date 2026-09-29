# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      class HtmlInStringLiteral < Base
        MSG = "Do not build HTML in Ruby strings. Use `tag`, `content_tag`, `link_to`, `mail_to`, `safe_join` " \
              "or a partial, which escape their arguments."

        HTML_TAG = %r{<(?:[a-z][a-z0-9]*[\s/>]|/[a-z][a-z0-9]*\s*>)}i
        FORMAT_REFERENCE = /%<\w+>/

        ENCLOSING_LITERAL_TYPES = %i[dstr dsym xstr regexp].freeze

        SEARCH_METHODS = %i[
          include? start_with? end_with? index rindex match match? split scan count delete
          gsub gsub! sub sub! == != eql?
        ].freeze

        def on_str(node)
          return if part_of_another_literal?(node)

          check(node, node.value)
        end

        def on_dstr(node)
          return if part_of_another_literal?(node)

          check(node, node.each_child_node(:str).map(&:value).join)
        end

        private

          def check(node, value)
            return unless value.valid_encoding? && HTML_TAG.match?(value.gsub(FORMAT_REFERENCE, ""))
            return if search_argument?(node)

            add_offense(node)
          end

          def part_of_another_literal?(node)
            ENCLOSING_LITERAL_TYPES.include?(node.parent&.type)
          end

          def search_argument?(node)
            parent = node.parent
            return false unless parent&.call_type? && SEARCH_METHODS.include?(parent.method_name)

            parent.first_argument.equal?(node) || (parent.comparison_method? && parent.receiver.equal?(node))
          end
      end
    end
  end
end
