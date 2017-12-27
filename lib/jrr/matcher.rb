require 'jrr/token'

module Jrr
  class Matcher
    attr_reader :children, :categories, :values

    def initialize(categories = nil, values = nil, children = [])
      # store categories and values as hash to optimize key lookup, h/t @jan-mangs
      @categories = [categories].compact.flatten.each_with_object({}) { |c, h| h[c] = 1 }
      @values     = [values].compact.flatten.each_with_object({}) { |v, h| h[v] = 1 }
      @children   = children.compact
      @invert     = false

      @min = 1
      @max = 1
      @range = (@min..@max)
    end

    def | (other_matcher)
      self.class.new(:nomatch, :nomatch, leaf_matchers + other_matcher.leaf_matchers)
    end

    def invert
      @invert = ! @invert
      self
    end

    def ==(token)
      leaf_matcher? ? matches_token?(token) : any_child_matches_token?(token)
    end

    def match(token_stream, offset = 0)
      matched_tokens = []
      matched = false

      while self == token_stream[matched_tokens.length + offset] && matched_tokens.length < @max
        matched_tokens << token_stream[matched_tokens.length + offset]
      end

      if @range.cover?(matched_tokens.length)
        matched = true
      end

      [matched, matched_tokens]
    end

    def caret
      @caret = true
      self
    end

    def caret?
      @caret
    end

    def star
      @min = 0
      @max = Float::INFINITY
      @range = (@min..@max)
      self
    end

    def plus
      @max = Float::INFINITY
      @range = (@min..@max)
      self
    end

    def leaf_matcher?
      children.empty?
    end

    def leaf_matchers
      leaf_matcher? ? [self] : children
    end

    private

    def any_child_matches_token?(token)
      children.any? { |child| child == token }
    end

    def matches_token?(token)
      return false if token.nil?
      (category_match(token.category) && value_match(token.value)) ^ @invert
    end

    def category_match(category)
      @categories.empty? || @categories.key?(category)
    end

    def value_match(value)
      @values.empty? || @values.key?(value)
    end

    def self.datetime;            new(:datetime);                       end
    def self.numeric;             new(:numeric);                        end
    def self.string;              new(:string);                         end
    def self.boolean;             new(:boolean);                        end
    def self.value
      new(:datetime) | new(:numeric) | new(:string) | new(:boolean)
    end

    def self.addsub;              new(:arithmetic_operator, [:add, :subtract]);    end
    def self.subtract;            new(:arithmetic_operator, :subtract);            end
    def self.anchored_minus;      new(:arithmetic_operator, :subtract).caret;      end
    def self.muldiv;              new(:arithmetic_operator, [:multiply, :divide]); end
    def self.pow;                 new(:arithmetic_operator, :pow);                 end
    def self.mod;                 new(:arithmetic_operator, :mod);                 end

    def self.boolean_operator;    new(:boolean_operator);                end

    def self.comparison_operator; new(:comparison_operator);             end
    def self.comp_gt;             new(:comparison_operator, [:gt, :ge]); end
    def self.comp_lt;             new(:comparison_operator, [:lt, :le]); end

    def self.open;                new(:grouping, :open);                 end
    def self.close;               new(:grouping, :close);                end
    def self.comma;               new(:grouping, :comma);                end
    def self.non_group;           new(:grouping).invert;                 end
    def self.non_group_star;      new(:grouping).invert.star;            end
    def self.non_close_plus;      new(:grouping, :close).invert.plus;    end
    def self.arguments;           (value | comma).plus;                  end

    def self.if;                  new(:function, :if);                   end
    def self.round;               new(:function, :round);                end
    def self.roundup;             new(:function, :roundup);              end
    def self.rounddown;           new(:function, :rounddown);            end
    def self.not;                 new(:function, :not);                  end

    def self.method_missing(name, *args, &block)
      new(:function, name)
    end

    def self.respond_to_missing?(name, include_priv)
      true
    end
  end
end
