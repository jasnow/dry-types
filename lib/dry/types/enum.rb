# frozen_string_literal: true

require 'dry/types/decorator'

module Dry
  module Types
    class Enum
      include Type
      include Dry::Equalizer(:type, :mapping, inspect: false)
      include Decorator

      # @return [Array]
      attr_reader :values

      # @return [Hash]
      attr_reader :mapping

      # @return [Hash]
      attr_reader :inverted_mapping

      # @param [Type] type
      # @param [Hash] options
      # @option options [Array] :values
      def initialize(type, options)
        super
        @mapping = options.fetch(:mapping).freeze
        @values = @mapping.keys.freeze
        @inverted_mapping = @mapping.invert.freeze
        freeze
      end

      # @api private
      # @return [Object]
      def call_unsafe(input)
        type.call_unsafe(map_value(input))
      end

      # @api private
      # @return [Object]
      def call_safe(input, &block)
        type.call_safe(map_value(input), &block)
      end

      # @see Dry::Types::Constrained#try
      def try(input)
        super(map_value(input))
      end

      def default(*)
        raise '.enum(*values).default(value) is not supported. Call '\
              '.default(value).enum(*values) instead'
      end

      # Check whether a value is in the enum
      alias_method :include?, :valid?

      # @see Nominal#to_ast
      def to_ast(meta: true)
        [:enum, [type.to_ast(meta: meta), mapping]]
      end

      # @return [String]
      def to_s
        PRINTER.(self)
      end
      alias_method :inspect, :to_s

      private

      # Maps a value
      #
      # @api private
      #
      # @param [Object] input
      # @return [Object]
      def map_value(input)
        if input.equal?(Undefined)
          type.call
        elsif mapping.key?(input)
          input
        else
          inverted_mapping.fetch(input, input)
        end
      end
    end
  end
end
