# frozen_string_literal: true

RSpec.describe Rubocop::It::Params do
  it "has a version number" do
    expect(Rubocop::It::Params::VERSION).not_to be_nil
  end
end
