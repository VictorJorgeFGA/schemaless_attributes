# frozen_string_literal: true

require 'active_record/type'

module SchemalessAttributes
  # This class is a helper which grants the ability to handle type casting
  # and enforces standard throughtout the code for those who need to use
  # ActiveRecord::Type API.
  class Type
    class << self
      def available_types
        %i[integer float decimal boolean date datetime time string text]
      end

      def type_available?(type)
        available_types.include?(type.to_sym)
      end

      # Instantiate a new ActiveRecord::Type for the given type
      #
      # @param type [String, Symbol] The needed type caster
      #
      # @return ActiveRecord::Type The corresponding ActiveRecord::Type
      #   for `type`. If type doesn't have a corresponding ActiveRecord::Type, an excpetion will be raised
      #
      def handler(type)
        raise "Type #{type} is not supported!" unless type_available?(type)

        send(type.to_sym)
      end

      def float
        @float ||= ActiveRecord::Type::Float.new
      end

      def decimal
        @decimal ||= ActiveRecord::Type::Decimal.new
      end

      def boolean
        @boolean ||= ActiveRecord::Type::Boolean.new
      end

      def date
        @date ||= ActiveRecord::Type::Date.new
      end

      def datetime
        @datetime ||= ActiveRecord::Type::DateTime.new
      end

      def time
        @time ||= ActiveRecord::Type::Time.new
      end

      def string
        @string ||= ActiveRecord::Type::String.new
      end

      def text
        @text ||= ActiveRecord::Type::Text.new
      end

      def integer
        @integer ||= ActiveRecord::Type::Integer.new
      end
    end
  end
end
