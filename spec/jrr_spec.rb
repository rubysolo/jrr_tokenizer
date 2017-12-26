require "spec_helper"

RSpec.describe Jrr do
  it "has a version number" do
    expect(Jrr::VERSION).not_to be nil
  end

  it "parses text into tokens" do
    tokens = Jrr.tokenize('y = m*x + b')
    expect(tokens.map(&:category)).to eq [
      :identifier,
      :comparison_operator,
      :identifier,
      :arithmetic_operator,
      :identifier,
      :arithmetic_operator,
      :identifier
    ]
  end
end
