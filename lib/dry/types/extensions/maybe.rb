# frozen_string_literal: true

require 'dry/monads/maybe'
require 'dry/types/decorator'

module Dry
  module Types
    # Maybe extension provides Maybe types where values are wrapped using `Either` monad
    #
    # @api public
    class Maybe
      include Type
      include Dry::Equalizer(:type, :options, inspect: false, immutable: true)
      include Decorator
      include Builder
      include Printable
      include Dry::Monads::Maybe::Mixin

      # @param [Dry::Monads::Maybe, Object] input
      #
      # @return [Dry::Monads::Maybe]
      #
      # @api private
      def call_unsafe(input = Undefined)
        case input
        when Dry::Monads::Maybe
          input
        when Undefined
          None()
        else
          Maybe(type.call_unsafe(input))
        end
      end

      # @param [Dry::Monads::Maybe, Object] input
      #
      # @return [Dry::Monads::Maybe]
      #
      # @api private
      def call_safe(input = Undefined, &block)
        case input
        when Dry::Monads::Maybe
          input
        when Undefined
          None()
        else
          Maybe(type.call_safe(input, &block))
        end
      end

      # @param [Object] input
      #
      # @return [Result::Success]
      #
      # @api public
      def try(input = Undefined)
        res = if input.equal?(Undefined)
                None()
              else
                Maybe(type[input])
              end

        Result::Success.new(res)
      end

      # @return [true]
      #
      # @api public
      def default?
        true
      end

      # @param [Object] value
      #
      # @see Dry::Types::Builder#default
      #
      # @raise [ArgumentError] if nil provided as default value
      #
      # @api public
      def default(value)
        if value.nil?
          raise ArgumentError, 'nil cannot be used as a default of a maybe type'
        else
          super
        end
      end
    end

    module Builder
      # Turn a type into a maybe type
      #
      # @return [Maybe]
      #
      # @api public
      def maybe
        Maybe.new(Types['strict.nil'] | self)
      end
    end

    # @api private
    class Schema::Key
      # @api private
      def maybe
        __new__(type.maybe)
      end
    end

    # @api private
    class Printer
      MAPPING[Maybe] = :visit_maybe

      # @api private
      def visit_maybe(maybe)
        visit(maybe.type) do |type|
          yield "Maybe<#{type}>"
        end
      end
    end

    # Register non-coercible maybe types
    NON_NIL.each_key do |name|
      register("maybe.strict.#{name}", self["strict.#{name}"].maybe)
    end

    # Register coercible maybe types
    COERCIBLE.each_key do |name|
      register("maybe.coercible.#{name}", self["coercible.#{name}"].maybe)
    end
  end
end
