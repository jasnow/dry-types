# frozen_string_literal: true

RSpec.describe Dry::Types::Array do
  describe '#of' do
    context 'primitive' do
      shared_context 'array with a member type' do
        it 'returns an array with correct member values' do
          expect(array[Set[1, 2, 3]]).to eql(%w[1 2 3])
        end

        it_behaves_like Dry::Types::Nominal do
          subject(:type) { array }
        end
      end

      context 'using string identifiers' do
        subject(:array) { Dry::Types['coercible.array<coercible.string>'] }

        include_context 'array with a member type'
      end

      context 'try' do
        subject(:array) do
          Dry::Types['nominal.array'].of(Dry::Types['strict.string'])
        end

        it 'with a valid array' do
          expect(array.try(%w[a b])).to be_success
        end

        it 'an invalid type should be a failure' do
          expect(array.try('some string')).to be_failure
        end

        it 'a broken constraint should be a failure' do
          expect(array.try(['1', 2])).to be_failure
        end

        it 'a broken constraint with block' do
          expect(
            array.try(['1', '2', 3]) { |error| "error: #{error}" }
          ).to match(/error: 3/)
        end

        it 'an invalid type with a block' do
          expect(
            array.try('X') { |x| 'error: ' + x.to_s }
          ).to eql('error: X is not an array')
        end
      end

      context 'using method' do
        subject(:array) { Dry::Types['coercible.array'].of(Dry::Types['coercible.string']) }

        include_context 'array with a member type'
      end

      context 'using a constrained type' do
        subject(:array) do
          Dry::Types['array'].of(Dry::Types['coercible.integer'].constrained(gt: 2))
        end

        it 'passes values through member type' do
          expect(array[%w[3 4 5]]).to eql([3, 4, 5])
        end

        it 'raises when input is not valid' do
          expect { array[%w[1 2 3]] }.to raise_error(
            Dry::Types::ConstraintError,
            '"1" violates constraints (gt?(2, 1) failed)'
          )
        end

        it_behaves_like Dry::Types::Nominal do
          subject(:type) { array }
        end
      end

      context 'constructor types' do
        subject(:array) do
          Dry::Types['array'].of(Dry::Types['coercible.integer'])
        end

        it 'yields partially coerced values' do
          expect(array.(['1', 2, 'foo']) { |xs| xs }).to eql([1, 2, 'foo'])
        end
      end

      context 'undefined' do
        subject(:array) do
          Dry::Types['array'].of(
            Dry::Types['nominal.string'].constructor { |value|
              value == '' ? Dry::Types::Undefined : value
            }
          )
        end

        it 'filters out undefined values' do
          expect(array[['', 'foo']]).to eql(['foo'])
        end
      end
    end
  end

  describe '#valid?' do
    subject(:array) { Dry::Types['array'].of(Dry::Types['string']) }

    it 'detects invalid input of the completely wrong type' do
      expect(array.valid?(5)).to be(false)
    end

    it 'detects invalid input of the wrong member type' do
      expect(array.valid?([5])).to be(false)
    end

    it 'recognizes valid input' do
      expect(array.valid?(['five'])).to be(true)
    end
  end

  describe '#===' do
    subject(:array) { Dry::Types['strict.array'].of(Dry::Types['strict.string']) }

    it 'returns boolean' do
      expect(array.===(%w[hello world])).to eql(true)
      expect(array.===(['hello', 1234])).to eql(false)
    end

    context 'in case statement' do
      let(:value) do
        case %w[hello world]
        when array then 'accepted'
        else 'invalid'
        end
      end

      it 'returns correct value' do
        expect(value).to eql('accepted')
      end
    end
  end

  context 'member' do
    describe '#to_s' do
      subject(:type) { Dry::Types['nominal.array'].of(Dry::Types['nominal.string']) }

      it 'returns string representation of the type' do
        expect(type.to_s).to eql('#<Dry::Types[Array<Nominal<String>>]>')
      end

      it 'shows meta' do
        expect(type.meta(foo: :bar).to_s).to eql('#<Dry::Types[Array<Nominal<String> meta={foo: :bar}>]>')
      end
    end

    describe '#constructor' do
      subject(:type) { Dry::Types['params.array<params.integer>'] }

      example 'getting member from a constructor type' do
        expect(type.member.('1')).to be(1)
      end

      describe '#lax' do
        subject(:type) { Dry::Types['array<integer>'].constructor(&:to_a) }

        it 'makes type recursively lax' do
          expect(type.lax.member).to eql(Dry::Types['nominal.integer'])
        end
      end

      describe '#constrained' do
        it 'applies constraints on top of constructor' do
          expect(type.constrained(size: 1).(['1'])).to eql([1])
          expect(type.constrained(size: 1).([]) { :fallback }).to be(:fallback)
        end
      end
    end

    context 'nested array' do
      let(:strings) do
        Dry::Types['array'].of('string')
      end

      subject(:type) do
        Dry::Types['array'].of(strings)
      end

      it 'still discards constructor' do
        expect(type.constructor(&:to_a).member.type).to eql(strings)
      end
    end
  end

  describe '#to_s' do
    subject(:type) { Dry::Types['nominal.array'] }

    it 'returns string representation of the type' do
      expect(type.to_s).to eql('#<Dry::Types[Array]>')
    end

    it 'adds meta' do
      expect(type.meta(foo: :bar).to_s).to eql('#<Dry::Types[Array meta={foo: :bar}]>')
    end
  end
end
