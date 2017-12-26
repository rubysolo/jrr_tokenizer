module Jrr
  class Token
    attr_reader :category, :value, :raw_value

    def initialize(category, value, raw_value=nil)
      @category = category
      @value = value
      @raw_value = raw_value
    end

    def to_s
      (raw_value || value).to_s
    end

    def length
      raw_value.to_s.length
    end

    def empty?
      length.zero?
    end

    def is?(some_category)
      category == some_category
    end

    def ==(other_token)
      is?(other_token.category) && value == other_token.value
    end
  end
end
