require "jrr/version"

module Jrr
  def self.tokenize(input)
    Tokenizer.new.tokenize(input)
  end
end
