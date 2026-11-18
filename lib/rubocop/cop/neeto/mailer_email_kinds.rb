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
        MISSING_MSG = "Declare `email_kinds` for %<actions>s, " \
          "e.g. `email_kinds transactional: %%i[...], user_generated: %%i[...]`."
        UNDECLARED_MSG = "Add `%<action>s` to `transactional` or `user_generated` in `email_kinds`."
        BOTH_MSG = "`%<action>s` is in both `transactional` and `user_generated`. Keep it in one."
        UNKNOWN_MSG = "`%<action>s` is listed in `email_kinds` but this mailer doesn't define it."
        NOT_A_LIST_MSG = "List the actions by name, e.g. `%%i[member_email]`."

        # @!method email_kinds_call?(node)
        def_node_matcher :email_kinds_call?, "(send nil? :email_kinds ...)"

        def on_class(node)
          name = node.identifier.short_name.to_s
          return if !name.end_with?("Mailer") || name == "ApplicationMailer"

          actions = public_actions(node)
          return if actions.empty?

          declaration = body_nodes(node).find { |child| email_kinds_call?(child) }
          if declaration.nil?
            listed = actions.keys.map { |name| "`#{name}`" }.join(", ")
            add_offense(node.identifier, message: format(MISSING_MSG, actions: listed))
          else
            check_declaration(declaration, actions)
          end
        end

        private

          def check_declaration(declaration, actions)
            lists = declared_lists(declaration)
            return if lists.nil?

            transactional = lists[:transactional]
            user_generated = lists[:user_generated]

            actions.each do |name, def_node|
              next if transactional.key?(name) || user_generated.key?(name)

              add_offense(def_node.loc.name, message: format(UNDECLARED_MSG, action: name))
            end

            (transactional.keys & user_generated.keys).each do |name|
              add_offense(user_generated[name], message: format(BOTH_MSG, action: name))
            end

            transactional.merge(user_generated).each do |name, sym_node|
              add_offense(sym_node, message: format(UNKNOWN_MSG, action: name)) unless actions.key?(name)
            end
          end

          # { transactional: { name => node }, user_generated: { name => node } }, or nil when
          # a list isn't a literal the cop can read. A bare symbol (e.g. `:all`) is an offense.
          def declared_lists(declaration)
            options = declaration.last_argument
            return { transactional: {}, user_generated: {} } if options.nil?
            return unless options.hash_type?

            lists = { transactional: {}, user_generated: {} }
            options.pairs.each do |pair|
              key = pair.key.sym_type? ? pair.key.value : nil
              next unless lists.key?(key)

              value = pair.value
              if value.array_type? && value.values.all?(&:sym_type?)
                lists[key] = value.values.to_h { |sym| [sym.value, sym] }
              else
                add_offense(value, message: format(NOT_A_LIST_MSG)) if value.sym_type?
                return
              end
            end
            lists
          end

          # Public `def`s in the class body, tracking `private`/`protected`/`public`
          # sections, `private :name` and inline `private def name`.
          def public_actions(node)
            visibility = :public
            body_nodes(node).each_with_object({}) do |child, actions|
              if child.def_type?
                actions[child.method_name] = child if visibility == :public
              elsif child.send_type? && child.receiver.nil? && %i[private protected public].include?(child.method_name)
                if child.arguments.empty?
                  visibility = child.method_name
                elsif child.method_name != :public
                  child.arguments.select(&:sym_type?).each { |sym| actions.delete(sym.value) }
                end
              end
            end
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
