module Jrr
  class TokenizerError < StandardError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      parse_error too_many_opening_parentheses too_many_closing_parentheses
      unexpected_zero_width_match
    ].freeze

    def self.for(reason, **meta)
      unless VALID_REASONS.include?(reason)
        raise ::ArgumentError, "Unhandled #{reason}"
      end

      new reason, meta
    end
  end
end
