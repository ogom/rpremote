# frozen_string_literal: true

module Oximeter
  module Measurement
    class RollingSampleWindow
      attr_reader :count

      def initialize(capacity)
        unless capacity.is_a?(Integer) && capacity > 0
          raise ArgumentError, "capacity must be a positive Integer"
        end

        @capacity = capacity
        @values = []
        @count = 0
      end

      def push(value)
        if @values.length >= @capacity
          index = 1
          while index < @values.length
            @values[index - 1] = @values[index]
            index += 1
          end
          @values[@values.length - 1] = value
        else
          @values << value
          @count += 1
        end
        value
      end

      def average
        return 0.0 if @count.zero?

        total = 0.0
        index = 0
        while index < @count
          total += @values[index]
          index += 1
        end
        total / @count
      end

      def standard_deviation
        return 0.0 if @count.zero?

        mean = average
        total = 0.0
        index = 0
        while index < @count
          difference = @values[index] - mean
          total += difference * difference
          index += 1
        end
        Math.sqrt(total / @count)
      end

      def clear
        @values = []
        @count = 0
        self
      end
    end
  end
end
