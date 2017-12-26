require 'spec_helper'
require 'jrr/scanner'

RSpec.describe Jrr::Scanner do
  let(:numeric)    { described_class.numeric }
  let(:whitespace) { described_class.whitespace }

  after { described_class.register_default_scanners }

  it 'returns a list of scanned tokens when the input matches' do
    tokens = whitespace.scan(' ')
    expect(tokens.length).to eq(1)
    token = tokens.first
    expect(token.category).to eq(:whitespace)
    expect(token.value).to eq(' ')
  end

  it 'returns false when the input does not match' do
    expect(whitespace.scan('A')).to be_falsy
  end

  it 'converts string values to the correct type' do
    token = numeric.scan('5').first
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
    expect(token.raw_value).to eq('5')
  end

  it 'uses default scanner list' do
    active_scanners = described_class.scanners
    expect(active_scanners.length).to eq(described_class.default_scanners.length)
  end

  it 'customizes scanner list' do
    described_class.scanners = [:whitespace, :numeric]
    expect(described_class.scanners.length).to eq 2
  end

  it 'ignores invalid scanners' do
    described_class.scanners = [:whitespace, :numeric, :fake]
    expect(described_class.scanners.length).to eq 2
  end

  it 'uses a custom scanner' do
    custom = described_class.new(:identifier, '#\w+\b', ->(raw) {
      raw[1..-1].to_sym
    })

    described_class.scanners = [:whitespace, :numeric]
    described_class.register_scanner(:custom, custom)
    expect(described_class.scanners.length).to eq 3

    token = custom.scan('#apple + #pear').first
    expect(token.category).to eq(:identifier)
    expect(token.value).to eq(:apple)
  end

  context 'default scanners' do
    it 'scans a NULL literal' do
      scanner = described_class.null
      token = scanner.scan('null').first
      expect(token.category).to eq(:null)
      expect(token.value).to be_nil
      expect(token.raw_value).to eq('null')
    end

    it 'scans whitespace' do
      scanner = described_class.whitespace
      token = scanner.scan('    ').first
      expect(token.category).to eq(:whitespace)
      expect(token.value).to eq(' ')
      expect(token.raw_value).to eq('    ')
    end

    it 'scans datetime' do
      scanner = described_class.datetime
      token = scanner.scan('2017-12-24 23:59:59').first
      expect(token.category).to eq(:datetime)
      expect(token.value).to eq(Time.local(2017, 12, 24, 23, 59, 59).to_datetime)
      expect(token.raw_value).to eq('2017-12-24 23:59:59')
    end

    it 'scans numeric' do
      scanner = described_class.numeric
      token = scanner.scan('2017').first
      expect(token.category).to eq(:numeric)
      expect(token.value).to eq(2017)
      expect(token.raw_value).to eq('2017')
    end

    it 'scans hexadecimal' do
      scanner = described_class.hexadecimal
      token = scanner.scan('0xCaFe').first
      expect(token.category).to eq(:numeric)
      expect(token.value).to eq(51966)
      expect(token.raw_value).to eq('0xCaFe')
    end

    it 'scans double quoted string' do
      scanner = described_class.double_quoted_string
      token = scanner.scan('"hello"').first
      expect(token.category).to eq(:string)
      expect(token.value).to eq('hello')
      expect(token.raw_value).to eq('"hello"')
    end

    it 'scans single quoted string' do
      scanner = described_class.single_quoted_string
      token = scanner.scan("'hello'").first
      expect(token.category).to eq(:string)
      expect(token.value).to eq('hello')
      expect(token.raw_value).to eq("'hello'")
    end

    it 'scans a negate symbol' do
      scanner = described_class.negate
      token = scanner.scan('-1').first
      expect(token.category).to eq(:arithmetic_operator)
      expect(token.value).to eq(:negate)
      expect(token.raw_value).to eq('-')
    end

    it 'scans a boolean operator' do
      scanner = described_class.boolean_operator
      token = scanner.scan('and how').first
      expect(token.category).to eq(:boolean_operator)
      expect(token.value).to eq(:and)
      expect(token.raw_value).to eq('and ')
    end

    it 'scans an arithmetic operator' do
      scanner = described_class.arithmetic_operator
      token = scanner.scan('+').first
      expect(token.category).to eq(:arithmetic_operator)
      expect(token.value).to eq(:add)
      expect(token.raw_value).to eq('+')
    end

    it 'scans an grouping symbol' do
      scanner = described_class.grouping
      token = scanner.scan('(').first
      expect(token.category).to eq(:grouping)
      expect(token.value).to eq(:open)
      expect(token.raw_value).to eq('(')
    end

    it 'scans an array access symbol' do
      scanner = described_class.access
      token = scanner.scan('[').first
      expect(token.category).to eq(:access)
      expect(token.value).to eq(:lbracket)
      expect(token.raw_value).to eq('[')
    end

    it 'scans a case statement' do
      scanner = described_class.case_statement
      token = scanner.scan('case').first
      expect(token.category).to eq(:case)
      expect(token.value).to eq(:open)
      expect(token.raw_value).to eq('case')
    end

    it 'scans a comparison operator' do
      scanner = described_class.comparison_operator
      token = scanner.scan('>').first
      expect(token.category).to eq(:comparison_operator)
      expect(token.value).to eq(:gt)
      expect(token.raw_value).to eq('>')
    end

    it 'scans a boolean literal' do
      scanner = described_class.boolean
      token = scanner.scan('true').first
      expect(token.category).to eq(:boolean)
      expect(token.value).to eq(true)
      expect(token.raw_value).to eq('true')
    end

    it 'scans a function call' do
      scanner = described_class.function
      token = scanner.scan('ROUND(3.5)').first
      expect(token.category).to eq(:function)
      expect(token.value).to eq(:round)
      expect(token.raw_value).to eq('ROUND')
    end

    it 'scans a variable identifier' do
      scanner = described_class.identifier
      token = scanner.scan('Hello').first
      expect(token.category).to eq(:identifier)
      expect(token.value).to eq('hello')
      expect(token.raw_value).to eq('Hello')
    end
  end
end
