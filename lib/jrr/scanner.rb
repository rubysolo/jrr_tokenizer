require 'jrr/default_scanners'
require 'jrr/token'

module Jrr
  class Scanner
    attr_reader :category, :regex, :converter, :condition
    extend DefaultScanners

    def initialize(category, regex, converter=nil, condition=nil)
      @category  = category
      @regex     = %r[\A(#{ regex })]i
      @converter = converter
      @condition = condition || ->(*) { true }
    end

    def scan(input, previous_token=nil)
      if (m = regex.match(input)) && continue?(previous_token)
        raw = m.to_s

        return Array(convert(raw)).map do |value|
          case value
          when Token then value
          else Token.new(category, value, raw)
          end
        end
      end

      false
    end

    def continue?(previous_token)
      condition.call(previous_token)
    end

    def convert(raw_value)
      if converter
        converter.call(raw_value)
      else
        raw_value
      end
    end

    def self.default_scanners
      [
        :null,
        :whitespace,
        :datetime,
        :numeric,
        :hexadecimal,
        :double_quoted_string,
        :single_quoted_string,
        :negate,
        :boolean_operator,
        :arithmetic_operator,
        :grouping,
        :access,
        :case_statement,
        :comparison_operator,
        :boolean,
        :function,
        :identifier
      ]
    end

    def self.register_default_scanners
      @scanners = default_scanners.map { |key| [key, self.send(key)] }
    end

    def self.scanners=(keys)
      @scanners.select! { |(key,_)| keys.include?(key) }
    end

    def self.register_scanner(key, scanner)
      @scanners.push([key, scanner])
    end

    def self.scanners(options={})
      @scanners.map { |(_, scanner)| scanner }
    end

    register_default_scanners
  end
end
