# frozen_string_literal: true

require_relative "lib/rubocop/prefer_it_parameter/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-prefer_it_parameter"
  spec.version = RuboCop::PreferItParameter::VERSION
  spec.authors = ["Takeshi KOMIYA"]
  spec.email = ["i.tkomiya@gmail.com"]

  spec.summary = "A RuboCop plugin that recommends using the `it` block parameter."
  spec.description = "A RuboCop plugin that recommends using the `it` block parameter " \
                     "instead of named block arguments in single-line blocks."
  spec.homepage = "https://github.com/tk0miya/rubocop-prefer_it_parameter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::PreferItParameter::Plugin"
  spec.metadata["source_code_uri"] = "https://github.com/tk0miya/rubocop-prefer_it_parameter"
  spec.metadata["changelog_uri"] = "https://github.com/tk0miya/rubocop-prefer_it_parameter/blob/main/CHANGELOG.md"

  # Requiring MFA for gem pushes helps protect your gem from supply chain
  # attacks by ensuring no one can publish a new version without
  # multi-factor authentication.
  # See: https://guides.rubygems.org/mfa-requirement-opt-in/
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  # NOTE: Matched as prefixes, so "Gemfile" also covers "Gemfile.lock".
  #       Entries are sorted in ASCII order.
  development_only = %w[
    .claude/ .github/ .gitignore .rspec .rubocop.yml .vscode/
    Gemfile Rakefile Steepfile bin/ rbs_collection.lock.yaml rbs_collection.yaml spec/
  ]
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*development_only)
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.0"
  spec.add_dependency "rubocop", ">= 1.75.0"
end
