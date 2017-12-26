require 'spec_helper'
require 'jrr/matcher'
require 'jrr/token'

RSpec.describe Jrr::Matcher do
  it 'with single category matches token category' do
    matcher = described_class.new(:numeric)
    token   = Jrr::Token.new(:numeric, 5)

    expect(matcher).to eq(token)
  end

  it 'with multiple categories matches any included token category' do
    matcher    = described_class.new([:comparator, :operator])
    numeric    = Jrr::Token.new(:numeric, 5)
    comparator = Jrr::Token.new(:comparator, :lt)
    operator   = Jrr::Token.new(:operator, :add)

    expect(matcher).to eq(comparator)
    expect(matcher).to eq(operator)
    expect(matcher).not_to eq(numeric)
  end

  it 'with single category and value matches token category and value' do
    matcher     = described_class.new(:operator, :add)
    addition    = Jrr::Token.new(:operator, :add)
    subtraction = Jrr::Token.new(:operator, :subtract)

    expect(matcher).to eq(addition)
    expect(matcher).not_to eq(subtraction)
  end

  it 'with multiple values matches any included token value' do
    matcher = described_class.new(:operator, [:add, :subtract])
    add = Jrr::Token.new(:operator, :add)
    sub = Jrr::Token.new(:operator, :subtract)
    mul = Jrr::Token.new(:operator, :multiply)
    div = Jrr::Token.new(:operator, :divide)

    expect(matcher).to eq(add)
    expect(matcher).to eq(sub)
    expect(matcher).not_to eq(mul)
    expect(matcher).not_to eq(div)
  end

  it 'is invertible' do
    matcher = described_class.new(:operator, [:add, :subtract]).invert
    add = Jrr::Token.new(:operator, :add)
    mul = Jrr::Token.new(:operator, :multiply)
    cmp = Jrr::Token.new(:comparator, :lt)

    expect(matcher).not_to eq(add)
    expect(matcher).to eq(mul)
    expect(matcher).to eq(cmp)
  end

  describe 'combining multiple tokens' do
    let(:numeric) { described_class.new(:numeric) }
    let(:string)  { described_class.new(:string) }

    it 'matches either' do
      either = numeric | string
      expect(either).to eq(Jrr::Token.new(:numeric, 5))
      expect(either).to eq(Jrr::Token.new(:string, 'rhubarb'))
    end

    it 'matches any value' do
      value = described_class.value
      expect(value).to eq(Jrr::Token.new(:numeric, 8))
      expect(value).to eq(Jrr::Token.new(:string, 'apricot'))
      expect(value).to eq(Jrr::Token.new(:logical, false))
      expect(value).not_to eq(Jrr::Token.new(:function, :round))
      expect(value).not_to eq(Jrr::Token.new(:identifier, :hello))
    end
  end

  describe 'stream matching' do
    let(:stream) { token_stream(5, 11, 9, 24, :hello, 8) }

    describe 'standard' do
      let(:standard) { described_class.new(:numeric) }

      it 'matches zero or more occurrences in a token stream' do
        matched, substream = standard.match(stream)
        expect(matched).to be_truthy
        expect(substream.length).to eq 1
        expect(substream.map(&:value)).to eq [5]

        matched, substream = standard.match(stream, 4)
        expect(substream).to be_empty
        expect(matched).not_to be_truthy
      end
    end

    describe 'star' do
      let(:star) { described_class.new(:numeric).star }

      it 'matches zero or more occurrences in a token stream' do
        matched, substream = star.match(stream)
        expect(matched).to be_truthy
        expect(substream.length).to eq 4
        expect(substream.map(&:value)).to eq [5, 11, 9, 24]

        matched, substream = star.match(stream, 4)
        expect(substream).to be_empty
        expect(matched).to be_truthy
      end
    end

    describe 'plus' do
      let(:plus) { described_class.new(:numeric).plus }

      it 'matches one or more occurrences in a token stream' do
        matched, substream = plus.match(stream)
        expect(matched).to be_truthy
        expect(substream.length).to eq 4
        expect(substream.map(&:value)).to eq [5, 11, 9, 24]

        matched, substream = plus.match(stream, 4)
        expect(substream).to be_empty
        expect(matched).not_to be_truthy
      end
    end

    describe 'arguments' do
      it 'matches comma-separated values' do
        stream = token_stream(1, :comma, 2, :comma, true, :comma, 'olive', :comma, :'(')
        matched, substream = described_class.arguments.match(stream)
        expect(matched).to be_truthy
        expect(substream.length).to eq 8
        expect(substream.map(&:value)).to eq [1, :comma, 2, :comma, true, :comma, 'olive', :comma]
      end
    end
  end

  private

  def token_stream(*args)
    args.map do |value|
      type = type_for(value)
      Jrr::Token.new(type, value)
    end
  end

  def type_for(value)
    case value
    when Numeric
      :numeric
    when String
      :string
    when true, false
      :logical
    when :add, :subtract, :multiply, :divide, :mod, :pow
      :operator
    when :open, :close, :comma
      :grouping
    when :lbracket, :rbracket
      :access
    when :le, :ge, :ne, :ne, :lt, :gt, :eq
      :comparator
    when :and, :or
      :combinator
    when :if, :round, :roundup, :rounddown, :not
      :function
    else
      :identifier
    end
  end
end
