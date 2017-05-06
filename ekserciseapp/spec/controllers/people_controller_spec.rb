# frozen_string_literal: true

require 'rails_helper'

describe PeopleController do
  let(:redis) { double(:redis) }
  let(:req_params) { { age: '7', name: 'me', phone: '638-2020' } }

  describe '#search' do
    let(:do_action) { post :search, params: req_params }
    before do
      allow(SecureRandom).to receive(:uuid).and_return '1234'
      allow(Redis).to receive(:current).and_return redis
      allow(redis).to receive(:mapped_hmset)
      allow(redis).to receive(:set)
    end

    it 'returns the guid' do
      do_action

      expect(JSON.parse(response.body)).to eq({ 'id' => '1234' })
      expect(response.status).to eq 201
    end

    it 'stores the params of the request in redis' do
      expect(redis).to receive(:mapped_hmset).with('requests:1234', req_params.merge!({ page: '1' }))
      do_action
    end

    it 'sets the ttl for the guid' do
      allow_any_instance_of(Random).to receive(:rand).and_return 7
      expect(redis).to receive(:set).with('requests:1234:ttl', 'nope', px: 7)
      do_action
    end

    context 'invalid request' do
      let(:req_params) { {} }

      it 'returns 405' do
        do_action
        expect(response.status).to eq 405
      end
    end
  end

  describe '#index' do
  end
end