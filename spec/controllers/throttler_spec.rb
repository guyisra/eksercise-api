# frozen_string_literal: true

require 'rails_helper'

describe Throttler do
  class FakeClass
    include Throttler

    def guid
      'guid'
    end

    def redis; end
  end

  let(:subject) { FakeClass.new }
  let(:redis) { double(:redis) }

  before do
    allow(subject).to receive(:redis).and_return redis
  end

  describe '#throttle!' do
    before do
      allow(redis).to receive(:ttl).and_return '10'
    end

    context 'over threshold' do
      before do
        allow(redis).to receive(:get).with(subject.throttling_key).and_return (Throttler::THRESHOLD + 10).to_s
        allow(redis).to receive(:expire)
      end

      it 'extends the cooldown period' do
        subject.throttle!
        expect(redis).to have_received(:expire)
      end

      it 'returns the ttl of the request' do
        expect(subject.throttle!).to eq '10'
      end
    end

    context 'under threshold' do
      before do
        allow(redis).to receive(:get).with(subject.throttling_key).and_return '1'
        allow(redis).to receive(:incr)
      end

      it 'increments the request amount' do
        allow(redis).to receive(:incr).with(subject.throttling_key).and_return '2'
        subject.throttle!
      end

      it 'returns false' do
        expect(subject.throttle!).to be_falsy
        expect(redis).to have_received(:incr).with(subject.throttling_key)
      end

      context 'first request' do
        it 'resets the expiration for the cooldown' do
          allow(redis).to receive(:incr).with(subject.throttling_key).and_return '1'
          allow(redis).to receive(:expire)
          subject.throttle!
        end
      end
    end
  end
end
