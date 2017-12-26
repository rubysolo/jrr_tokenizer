require 'bigdecimal'
require 'time'
require 'jrr/token'

module Jrr
  module DefaultScanners
    def null
      new(:null, 'null\b', ->(*) { [nil] })
    end

    def whitespace
      new(:whitespace, '\s+', ->(*) { ' ' })
    end

    def datetime
      new(:datetime, /\d{2}\d{2}?-\d{1,2}-\d{1,2}( \d{1,2}:\d{1,2}:\d{1,2})? ?(Z|((\+|\-)\d{2}\:?\d{2}))?/, ->(raw) {
        Time.parse(raw).to_datetime
      })
    end

    def numeric
      new(:numeric, '((?:\d+(\.\d+)?|\.\d+)(?:(e|E)(\+|-)?\d+)?)\b', ->(raw) {
        raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i
      })
    end

    def hexadecimal
      new(:numeric, '(0x[0-9a-f]+)\b', ->(raw) { raw[2..-1].to_i(16) })
    end

    def double_quoted_string
      new(:string, '"[^"]*"', ->(raw) { raw.gsub(/^"|"$/, '') })
    end

    def single_quoted_string
      new(:string, "'[^']*'", ->(raw) { raw.gsub(/^'|'$/, '') })
    end

    def negate
      new(:arithmetic_operator, '-', ->(raw) { :negate }, ->(previous_token) {
        previous_token.nil?                      ||
        previous_token.is?(:arithmetic_operator) ||
        previous_token.is?(:comparison_operator) ||
        previous_token.is?(:boolean_operator)    ||
        previous_token.value == :open            ||
        previous_token.value == :comma
      })
    end

    def boolean_operator
      names = { and: '&&', or: '||' }.invert

      new(:boolean_operator, '(and|or|&&|\|\|)\s+', ->(raw) {
        norm = raw.strip.downcase
        names.fetch(norm) { norm.to_sym }
      })
    end

    def arithmetic_operator
      names = {
        pow: '^', add: '+', subtract: '-', multiply: '*', divide: '/', mod: '%',
        bitor: '|', bitand: '&'
      }.invert

      new(:arithmetic_operator, '\^|\+|-|\*|\/|%|\||&', ->(raw) { names.fetch(raw) })
    end

    def grouping
      names = { open: '(', close: ')', comma: ',' }.invert
      new(:grouping, '\(|\)|,', ->(raw) { names.fetch(raw) })
    end

    def access
      names = { lbracket: '[', rbracket: ']' }.invert
      new(:access, '\[|\]', ->(raw) { names.fetch(raw) })
    end

    def case_statement
      names = { open: 'case', close: 'end', then: 'then', when: 'when', else: 'else' }.invert
      new(:case, '(case|end|then|when|else)\b', ->(raw) { names.fetch(raw.downcase) })
    end

    def comparison_operator
      names = { le: '<=', ge: '>=', ne: '!=', lt: '<', gt: '>', eq: '=' }.invert
      alternate = { ne: '<>', eq: '==' }.invert
      new(:comparison_operator, '<=|>=|!=|<>|<|>|==|=', ->(raw) {
        names.fetch(raw) { alternate.fetch(raw) }
      })
    end

    def boolean
      new(:boolean, '(true|false)\b', ->(raw) { raw.strip.downcase == 'true' })
    end

    def function
      new(:function, '\w+!?\s*\(', ->(raw) do
        function_name = raw.gsub('(', '')
        [
          Token.new(:function, function_name.strip.downcase.to_sym, function_name),
          Token.new(:grouping, :open, '(')
        ]
      end)
    end

    def identifier
      new(:identifier, '[\w\.]+\b', ->(raw) { standardize_case(raw.strip) })
    end

    def standardize_case(value)
      if @case_sensitive
        value
      else
        value.downcase
      end
    end
  end
end
