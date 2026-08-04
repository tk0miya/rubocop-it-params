# frozen_string_literal: true

require "lint_roller"
require "pathname"

require_relative "version"

module RuboCop
  module PreferItParameter
    class Plugin < LintRoller::Plugin
      # @rbs override
      def about
        LintRoller::About.new(
          name: "rubocop-prefer_it_parameter",
          version: VERSION,
          homepage: "https://github.com/tk0miya/rubocop-prefer_it_parameter",
          description: "A RuboCop plugin that recommends using the `it` block parameter " \
                       "instead of named block arguments in single-line blocks."
        )
      end

      # @rbs override
      def supported?(context)
        context.engine == :rubocop
      end

      # @rbs override
      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          # `__dir__` is `String?` in the RBS stubs, so `__FILE__` is used instead.
          value: Pathname.new(__FILE__).dirname.join("../../../config/default.yml").expand_path
        )
      end
    end
  end
end
