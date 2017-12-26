require 'spec_helper'
require 'jrr/token'

RSpec.describe Jrr::Token do
  it 'has a category and a value' do
    token = Jrr::Token.new(:numeric, 5)
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
    expect(token.is?(:numeric)).to be_truthy
  end

  it 'captures raw (string) value before conversion or typecast' do
    token = Jrr::Token.new(:numeric, 5, "5")
    expect(token.raw_value).to eq("5")
    expect(token.length).to eq(1)
    expect(token).not_to be_empty
  end

  it 'compares category and value to determine equality' do
    t1 = Jrr::Token.new(:numeric, 5)
    t2 = Jrr::Token.new(:numeric, 5)
    expect(t1 == t2).to be_truthy
  end

  it 'prefers raw value for string representation' do
    t1 = Jrr::Token.new(:numeric, 5)
    t2 = Jrr::Token.new(:numeric, 5, "five")
    expect(t1.to_s).to eq("5")
    expect(t2.to_s).to eq("five")
  end
end
