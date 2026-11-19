# frozen_string_literal: true

module RuboCop
  module Cop
    module Neeto
      # Every mailer declares which of its actions send transactional email
      # (content we control) and which send user-generated email (content a
      # person wrote). `neeto-email-pipeline-engine` sends user-generated email
      # from a separate domain, so an undeclared action stays on the default
      # domain. See neetozone/neeto-engineering#2319.
      #
      # Actions are the public instance methods defined in the mailer's class
      # body. Each one must be listed by name in exactly one list.
      #
      # @example
      #   # bad
      #   class MessageMailer < ApplicationMailer
      #     def customer_email; end
      #   end
      #
      #   # bad
      #   class MessageMailer < ApplicationMailer
      #     email_kinds user_generated: %i[customer_email]
      #
      #     def customer_email; end
      #     def member_email; end
      #   end
      #
      #   # good
      #   class MessageMailer < ApplicationMailer
      #     email_kinds transactional: %i[member_email], user_generated: %i[customer_email]
      #
      #     def customer_email; end
      #     def member_email; end
      #   end
      #
      class MailerEmailKinds < Base
        include VisibilityHelp

        MISSING_MSG = "Declare `email_kinds` for %<actions>s, " \
          "e.g. `email_kinds transactional: %%i[...], user_generated: %%i[...]`."
        UNDECLARED_MSG = "Add `%<action>s` to `transactional` or `user_generated` in `email_kinds`."
        BOTH_MSG = "`%<action>s` is in both `transactional` and `user_generated`. Keep it in one."
        UNKNOWN_MSG = "`%<action>s` is listed in `email_kinds` but this mailer doesn't define it."
        NOT_A_LIST_MSG = "List the actions by name, e.g. `%i[member_email]`."
        LIST_KEYS = %i[transactional user_generated].freeze

        # @!method email_kinds_call?(node)
        def_node_matcher :email_kinds_call?, "(send nil? :email_kinds ...)"

        def on_class(node)
          name = node.identifier.short_name.to_s
          return if !name.end_with?("Mailer") || name == "ApplicationMailer"

          children = body_nodes(node)
          actions = children.select { |child| child.def_type? && node_visibility(child) == :public }
            .to_h { |def_node| [def_node.method_name, def_node] }
          return if actions.empty?

          declaration = children.find { |child| email_kinds_call?(child) }
          if declaration.nil?
            listed = actions.keys.map { |action| "`#{action}`" }.join(", ")
            add_offense(node.identifier, message: format(MISSING_MSG, actions: listed))
          else
            check_declaration(declaration, actions)
          end
        end

        private

          def check_declaration(declaration, actions)
            options = declaration.last_argument
            return if options && !options.hash_type?

            pairs = options ? options.pairs.select { |pair| list_pair?(pair) } : []

            bare_symbol = pairs.map(&:value).find(&:sym_type?)
            return add_offense(bare_symbol, message: NOT_A_LIST_MSG) if bare_symbol
            return unless pairs.all? { |pair| pair.value.array_type? && pair.value.values.all?(&:sym_type?) }

            lists = LIST_KEYS.to_h { |key| [key, {}] }
            pairs.each { |pair| lists[pair.key.value] = pair.value.values.to_h { |sym| [sym.value, sym] } }
            transactional, user_generated = lists.values_at(*LIST_KEYS)
            declared = transactional.merge(user_generated)

            actions.each do |action, def_node|
              add_offense(def_node.loc.name, message: format(UNDECLARED_MSG, action:)) unless declared.key?(action)
            end

            (transactional.keys & user_generated.keys).each do |action|
              add_offense(user_generated[action], message: format(BOTH_MSG, action:))
            end

            declared.each do |action, sym_node|
              add_offense(sym_node, message: format(UNKNOWN_MSG, action:)) unless actions.key?(action)
            end
          end

          def list_pair?(pair)
            pair.key.sym_type? && LIST_KEYS.include?(pair.key.value)
          end

          def body_nodes(node)
            body = node.body
            return [] if body.nil?

            body.begin_type? ? body.children : [body]
          end
      end
    end
  end
end
