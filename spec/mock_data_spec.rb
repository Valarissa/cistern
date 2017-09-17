# frozen_string_literal: true

require 'spec_helper'

describe 'mock data' do
  before {
    class Sample::Diagnosis < Sample::Request
      def real(diagnosis)
      end

      def mock(diagnosis)
        cistern.data.store(:diagnosis, cistern.data.fetch(:diagnosis) + [diagnosis])
      end
    end

    class Sample::Treat < Sample::Request
      def real(treatment)
      end

      def mock(treatment)
        cistern.data[:treatments] += [treatment]
      end
    end
  }

  shared_examples 'mock_data#backend' do |backend, options|
    it 'should store mock data' do
      Sample.mock!
      Sample::Mock.store_in(backend, options)
      Sample.reset!

      p = Sample.new
      p.diagnosis('sick')
      expect(p.data[:diagnosis]).to eq(['sick'])

      p.reset!

      expect(p.data[:diagnosis]).to eq([])

      p.treat('healthy')
      expect(p.data[:treatments]).to eq(['healthy'])

      Sample.reset!

      expect(p.data[:treatments]).to eq([])
    end
  end

  context 'with a storage backend' do
    describe 'Cistern::Data::Hash' do
      include_examples 'mock_data#backend', :hash
    end

    describe 'Cistern::Data::Redis' do
      include_examples 'mock_data#backend', :redis

      context 'with an explicit client' do
        before(:each) do
          @other = Redis::Namespace.new('other_cistern', Redis.new)
          @other.set('x', 'y')
        end

        include_examples 'mock_data#backend', :redis, client: Redis::Namespace.new('cistern', Redis.new)

        after(:each) do
          expect(@other.get('x')).to eq('y')
          @other.del('x')
        end
      end
    end
  end
end
