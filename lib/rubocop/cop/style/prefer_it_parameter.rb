# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer the `it` block parameter over a named block argument in single-line blocks.
      #
      # Only blocks consisting of a single statement are converted. This cop complements
      # `Style/ItBlockParameter` in RuboCop core, which converts `_1` to `it` but in its
      # default style does not check named block arguments.
      #
      # @safety
      #   The autocorrection is unsafe because a local variable named `it` that the
      #   block does not reference cannot be detected, and replacing it would silently
      #   change what the block sees. Enabling `Style/ItAssignment` rules such names
      #   out. Additionally, `it` drops the argument name from `Proc#parameters`
      #   (`[[:opt, :x]]` becomes `[[:opt]]`) and breaks
      #   `binding.local_variable_get(:x)` inside the block. Blocks that define a
      #   callable or a method are skipped for that reason, but a block captured with
      #   `&block` and introspected elsewhere is still affected.
      #
      # @example
      #   # bad
      #   users.map { |user| user.name.upcase }
      #   items.select { |item| item.active? && item.visible? }
      #
      #   # good
      #   users.map { it.name.upcase }
      #   items.select { it.active? && it.visible? }
      #
      #   # good - multi-line block
      #   users.each do |user|
      #     user.activate!
      #     notify(user)
      #   end
      #
      #   # good - the block consists of two statements
      #   items.each { |item| validate(item); save(item) }
      #
      #   # good - only the innermost block may use `it`
      #   matrix.map { |row| row.map { it * 2 } }
      #
      #   # good - `|x,|` destructures the yielded value, unlike `it`
      #   pairs.each { |pair,| puts pair }
      #
      #   # good - a callable's parameter list is part of its API
      #   ->(x) { puts x }
      #   define_method(:m) { |x| x + 1 }
      #
      #   # bad
      #   items.map { |item| {item:} }
      #
      #   # good - the value is spelled out, since `{it:}` would call a method named `it`
      #   items.map { {item: it} }
      #
      class PreferItParameter < Base
        extend AutoCorrector
        extend TargetRubyVersion
        include RangeHelp

        minimum_target_ruby_version 3.4

        MSG = "Use the `it` block parameter instead of the named block argument `%<name>s`."

        INNER_BLOCK_TYPES = %i[block numblock itblock].freeze #: Array[Symbol]

        CALLABLE_METHODS = %i[define_method define_singleton_method lambda proc].freeze #: Array[Symbol]

        # @rbs node: RuboCop::AST::BlockNode
        def on_block(node) #: void
          body = node.body
          return unless body

          name = convertible_argument_name(node, body)
          return unless name

          references = lvar_references(body, name)
          return if references.empty?

          register_offense(node, name, references)
        end

        private

        # @rbs node: RuboCop::AST::BlockNode
        # @rbs body: RuboCop::AST::Node
        def convertible_argument_name(node, body) #: Symbol?
          return unless node.single_line?
          return if defines_callable?(node)

          name = sole_argument_name(node)
          return unless name
          return unless convertible_body?(body, name)
          return if shadows_it?(body)

          name
        end

        # `it` would not mean what the block expects when a local variable named `it`
        # is already in scope, or when the body assigns to `it` — assigning turns `it`
        # into a plain local variable and disables the implicit block parameter.
        #
        # @rbs body: RuboCop::AST::Node
        def shadows_it?(body) #: bool
          lvar_references(body, :it).any? || reassigned?(body, :it)
        end

        # `it` drops the parameter name from `Proc#parameters`, which changes the
        # meaning of a block that defines a callable object or a method: there the
        # parameter list is part of the API, unlike a block passed to `each` or `map`.
        #
        # @rbs node: RuboCop::AST::BlockNode
        def defines_callable?(node) #: bool
          CALLABLE_METHODS.include?(node.method_name) || proc_new?(node)
        end

        # @rbs node: RuboCop::AST::BlockNode
        def proc_new?(node) #: bool
          return false unless node.method?(:new)

          receiver = node.send_node.receiver
          return false unless receiver&.const_type?

          const = receiver #: RuboCop::AST::ConstNode
          const.short_name == :Proc
        end

        # @rbs node: RuboCop::AST::BlockNode
        def sole_argument_name(node) #: Symbol?
          return unless node.argument_list.one?

          argument = node.first_argument
          # Rules out optarg, restarg, kwarg, blockarg, shadowarg and mlhs at once.
          return unless argument&.arg_type?
          # `|x,|` is indistinguishable from `|x|` in the AST even though it
          # destructures the yielded value, so the source has to be checked.
          return if node.arguments.source&.include?(",")

          plain_argument = argument #: RuboCop::AST::ArgNode
          plain_argument.name
        end

        # @rbs body: RuboCop::AST::Node
        # @rbs name: Symbol
        def convertible_body?(body, name) #: bool
          single_statement?(body) && !contains_block?(body) && !reassigned?(body, name)
        end

        # `begin` (parentheses) and `kwbegin` (`begin ... end`) both wrap a sequence of
        # statements as well as a single expression, so the number of children is what
        # tells the two apart.
        #
        # @rbs body: RuboCop::AST::Node
        def single_statement?(body) #: bool
          return body.each_child_node.one? if body.type?(:begin, :kwbegin)

          true
        end

        # `it` is a syntax error inside a block that has an ordinary parameter, and
        # silently shadows the outer one inside a parameterless block, so only the
        # innermost block is converted.
        #
        # @rbs body: RuboCop::AST::Node
        def contains_block?(body) #: bool
          body.each_node(*INNER_BLOCK_TYPES).any?
        end

        # A block that rebinds the name cannot be converted: the value `it` refers to
        # would no longer be the one the block was yielded. `match_var` covers pattern
        # matching (`1 in x`), which rebinds just like an assignment.
        #
        # @rbs body: RuboCop::AST::Node
        # @rbs name: Symbol
        def reassigned?(body, name) #: bool
          body.each_node(:lvasgn, :match_var).any? do |node|
            node.to_a.first == name
          end
        end

        # Returns the enclosing pair when the reference is a value omission (`{x:}`,
        # `foo(x:)`). Such a reference shares its source range with the label, so the
        # value has to be written after the pair rather than replaced.
        #
        # @rbs reference: RuboCop::AST::Node
        def omitted_value_pair(reference) #: RuboCop::AST::PairNode?
          parent = reference.parent
          return unless parent&.pair_type?

          pair = parent #: RuboCop::AST::PairNode
          pair if pair.value_omission?
        end

        # @rbs body: RuboCop::AST::Node
        # @rbs name: Symbol
        def lvar_references(body, name) #: Array[RuboCop::AST::Node]
          body.each_node(:lvar).select do |node|
            variable = node #: RuboCop::AST::VarNode
            variable.name == name
          end
        end

        # @rbs node: RuboCop::AST::BlockNode
        # @rbs name: Symbol
        # @rbs references: Array[RuboCop::AST::Node]
        def register_offense(node, name, references) #: void
          add_offense(node.arguments, message: format(MSG, name:)) do |corrector|
            references.each do |reference|
              replace_reference(corrector, reference)
            end
            corrector.remove(arguments_removal_range(node))
          end
        end

        # @rbs corrector: RuboCop::Cop::Corrector
        # @rbs reference: RuboCop::AST::Node
        def replace_reference(corrector, reference) #: void
          pair = omitted_value_pair(reference)
          if pair
            corrector.insert_after(pair.source_range, " it")
          else
            corrector.replace(reference.source_range, "it")
          end
        end

        # @rbs node: RuboCop::AST::BlockNode
        def arguments_removal_range(node) #: Parser::Source::Range
          range_with_surrounding_space(node.arguments.source_range, side: :right, newlines: false)
        end
      end
    end
  end
end
