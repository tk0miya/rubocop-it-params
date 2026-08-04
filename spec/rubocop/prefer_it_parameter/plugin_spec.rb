# frozen_string_literal: true

require "yaml"

RSpec.describe RuboCop::PreferItParameter::Plugin do
  let(:plugin) { described_class.new({}) }

  describe "#supported?" do
    subject { plugin.supported?(context) }

    context "with the rubocop engine" do
      let(:context) { LintRoller::Context.new(engine: :rubocop) }

      it { is_expected.to be(true) }
    end

    context "with another engine" do
      let(:context) { LintRoller::Context.new(engine: :standard) }

      it { is_expected.to be(false) }
    end
  end

  describe "#rules" do
    subject { plugin.rules(LintRoller::Context.new(engine: :rubocop)) }

    it "points at a configuration listing exactly the cops this gem defines" do
      expect(File.exist?(subject.value)).to be(true)

      # Scoped to `lib/` so that gems vendored under the repository (for example via
      # `bundle config path vendor/bundle`) are not mistaken for this gem's own cops.
      lib_root = File.expand_path("../../../lib", __dir__)
      defined_here = RuboCop::Cop::Registry.global.cops.select do |cop|
        Object.const_source_location(cop.name)&.first&.start_with?("#{lib_root}/")
      end

      expect(defined_here).not_to be_empty
      expect(defined_here.map { it.badge.to_s })
        .to match_array(YAML.safe_load_file(subject.value).keys)
    end
  end
end
