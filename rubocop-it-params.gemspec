# frozen_string_literal: true

require_relative "lib/rubocop/it/params/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-it-params"
  spec.version = RuboCop::It::Params::VERSION
  spec.authors = ["Takeshi KOMIYA"]
  spec.email = ["i.tkomiya@gmail.com"]

  spec.summary = "A RuboCop plugin that recommends using the `it` block parameter."
  spec.description = "A RuboCop plugin that recommends using the `it` block parameter " \
                     "instead of named block arguments in single-line blocks."
  spec.homepage = "https://github.com/tk0miya/rubocop-it-params"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::It::Params::Plugin"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tk0miya/rubocop-it-params"
  spec.metadata["changelog_uri"] = "https://github.com/tk0miya/rubocop-it-params/blob/main/CHANGELOG.md"

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
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { File.basename(it) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.0"
  spec.add_dependency "rubocop", ">= 1.75.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://guides.rubygems.org/make-your-own-gem/
end
