# frozen_string_literal: true

require "yaml"

module RuboCop
  module Cop
    module Neeto
      # `I18n.t` does not escape interpolated values, even for `_html` keys
      # (only the view helper `t` does). A translation that contains HTML and
      # interpolates an unescaped value outside a view lets that value inject
      # markup. The cop reads the translations from `LocaleFiles`.
      #
      # @example HtmlTranslationInterpolation: true (default)
      #   # en.yml
      #   #   seed:
      #   #     description: "<p>Schedule a meeting with %{name}</p>"
      #
      #   # bad
      #   I18n.t("seed.description", name: user.name)
      #
      #   # good
      #   I18n.t("seed.description", name: ERB::Util.html_escape(user.name))
      #
      #   # good
      #   tag.p(I18n.t("seed.description_text", name: user.name))
      #
      class HtmlTranslationInterpolation < Base
        MSG = "Translation `%<key>s` contains HTML and interpolates %<variables>s, which `I18n.t` does not " \
              "escape. Escape each value with `ERB::Util.html_escape`, or keep the markup out of the translation " \
              "and build it with `tag` or `content_tag`."

        RESTRICT_ON_SEND = %i[t translate].freeze
        OPTIONS = %i[locale scope default raise throw count].freeze

        def_node_matcher :translation_call, <<~PATTERN
          (send {nil? (const {nil? cbase} :I18n)} {:t :translate} (str $_) $...)
        PATTERN

        def_node_matcher :escaped_value?, <<~PATTERN
          (send {nil? (const (const {nil? cbase} :ERB) :Util)} {:html_escape :h} _)
        PATTERN

        def self.translations_cache
          @_translations_cache ||= {}
        end

        def on_send(node)
          translation_call(node) do |key, arguments|
            options = arguments.last
            next unless options&.hash_type?

            translation = translations[key]
            next unless translation.is_a?(String) && HtmlInStringLiteral::HTML_TAG.match?(translation)

            variables = unescaped_variables(options).select { |name| translation.include?("%{#{name}}") }
            next if variables.empty?

            add_offense(node, message: format(MSG, key:, variables: variables.map { |name| "%{#{name}}" }.join(", ")))
          end
        end

        private

          def unescaped_variables(options)
            options.pairs.filter_map do |pair|
              next unless pair.key.sym_type?
              next if OPTIONS.include?(pair.key.value) || escaped_value?(pair.value)

              pair.key.value.to_s
            end
          end

          def translations
            self.class.translations_cache[locale_files] ||= locale_files.each_with_object({}) do |path, result|
              next unless File.exist?(path)

              YAML.safe_load_file(path, aliases: true)&.each_value { |tree| flatten(tree, nil, result) }
            end
          end

          def locale_files
            Array(cop_config["LocaleFiles"]).map { |path| File.expand_path(path, config.base_dir_for_path_parameters) }
          end

          def flatten(tree, prefix, result)
            return result[prefix] = tree unless tree.is_a?(Hash)

            tree.each { |key, value| flatten(value, [prefix, key].compact.join("."), result) }
          end
      end
    end
  end
end
