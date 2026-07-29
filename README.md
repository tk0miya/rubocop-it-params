# rubocop-it-params

A RuboCop plugin that recommends using the `it` block parameter (Ruby 3.4+) instead of named block arguments in single-line blocks.

## Installation

Add the gem to your application's Gemfile. RuboCop loads it through `plugins:`, so it does not need to be required:

```ruby
group :development do
  gem "rubocop-it-params", require: false
end
```

Or install it directly:

```bash
gem install rubocop-it-params
```

Then add it to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-it-params
```

## Cops

### Style/PreferItParameter

Prefer the `it` block parameter over a named block argument in single-line blocks. Only blocks consisting of a single statement are converted. This cop supports autocorrection.

**Bad:**

```ruby
users.map { |user| user.name.upcase }
items.select { |item| item.active? && item.visible? }
```

**Good:**

```ruby
users.map { it.name.upcase }
items.select { it.active? && it.visible? }
```

A value omission is spelled out, since `{it:}` would call a method named `it`:

```ruby
# bad
items.map { |item| {item:} }

# good
items.map { {item: it} }
```

The autocorrection is marked unsafe — see [Safety](#safety).

#### Exceptions

A block is left alone when it:

- is multi-line — a named argument reads better there
- has two or more statements
- contains a nested block — only the innermost block is converted
- takes anything other than a single plain argument, including a trailing comma such as `|x,|` (which destructures the yielded value while `it` does not)
- rebinds its argument, by assignment or by pattern matching
- never references its argument (see `Lint/UnusedBlockArgument`)
- references a local variable named `it` from an enclosing scope, or assigns to `it`
- already names its argument `it` — dropping it would revive an `it` from an enclosing scope (`Style/ItAssignment` forbids the name instead)
- defines a callable or a method — `->(x) { }`, `lambda`, `proc`, `Proc.new`, `define_method`, `define_singleton_method` — since the parameter list is part of its API and `it` drops the parameter name

## Related cops

### `Style/ItBlockParameter` (RuboCop core)

It ships as `Enabled: pending`, so it needs `NewCops: enable` or an explicit `Enabled: true`. Once enabled, the two cops do not conflict — they cover different cells of the same grid:

| | `Style/PreferItParameter` (this gem) | `Style/ItBlockParameter` (core, `allow_single_line`) |
|---|---|---|
| single-line block with a named argument | offense | — |
| single-line block using `_1` | — | offense |
| multi-line block using `_1` | — | offense |
| multi-line block using `it` | — | offense |
| multi-line block with a named argument | — | — |

Enabling both enforces "use `it` for single-line blocks, use a named argument for multi-line blocks" consistently.

Do not set core's cop to `EnforcedStyle: always` — it then checks named block arguments as well, and the two autocorrections collide on the same block.

### `Style/ItAssignment` (RuboCop core) — recommended

```yaml
Style/ItAssignment:
  Enabled: true
```

`Style/ItAssignment` forbids naming a local variable or parameter `it`, which `Style/PreferItParameter` cannot fully guard against on its own — see [Safety](#safety).

## Safety

The autocorrection is marked unsafe (`SafeAutoCorrect: false`), so `rubocop -a` reports the offenses without changing anything and `rubocop -A` is needed to apply them. `it` is not equivalent to a named argument in every respect:

- A local variable or parameter named `it` takes precedence over the block parameter. The cop skips a block that references such a variable, but it cannot detect one that the block never references — there the autocorrection silently changes what the block sees. Enabling `Style/ItAssignment` is therefore a prerequisite.
- `Proc#parameters` loses the argument name: `[[:opt, :x]]` becomes `[[:opt]]`. Blocks that define a callable or a method are excluded for this reason, but a block captured with `&block` and introspected elsewhere is still affected.
- `binding.local_variable_get(:x)` inside the block stops working.

## Requirements

- Ruby >= 3.4
- RuboCop >= 1.75.0

The cop only inspects projects whose `TargetRubyVersion` is 3.4 or higher, since that is when `it` was introduced.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rubocop-it-params. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tk0miya/rubocop-it-params/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubocop-it-params project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tk0miya/rubocop-it-params/blob/main/CODE_OF_CONDUCT.md).
