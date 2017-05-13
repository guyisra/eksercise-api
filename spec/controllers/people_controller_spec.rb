# frozen_string_literal: true

require 'rails_helper'

describe PeopleController do
  let(:guid) { '12345' }
  let(:redis) { double(:redis) }
  let(:req_params) { { age: '7', name: 'me', phone: '638-2020' } }
  let(:current_candidate) do
    Candidate.create(name:               'Candy',
                     key:                '12345',
                     evil_long_response: false,
                     evil_malformed:     false,
                     evil_wrong_results: false,
                     evil_throttling:    false)
  end

  before do
    allow(Redis).to receive(:current).and_return redis
  end

  describe '#search' do
    let(:do_action) { post :search, params: req_params }

    before do
      allow_any_instance_of(PeopleController).to receive(:current_candidate).and_return current_candidate
    end

    context 'authorized' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return guid
        allow(redis).to receive(:mapped_hmset)
        allow(redis).to receive(:set)
        allow(redis).to receive(:expire)
        allow_any_instance_of(PeopleController).to receive(:check_candidate_token).and_return true
      end

      it 'returns the guid' do
        do_action

        expect(JSON.parse(response.body)).to eq('id' => guid)
        expect(response.status).to eq 201
      end

      it 'stores the params of the request in redis' do
        expect(redis).to receive(:mapped_hmset).with("requests:#{guid}", req_params.merge!(page: '1'))
        do_action
      end

      it 'sets the ttl for the guid' do
        allow_any_instance_of(Random).to receive(:rand).and_return 7
        expect(redis).to receive(:set).with("requests:#{guid}:ttl", 'nope', px: 7)
        do_action
      end

      it 'sets the guid to expire' do
        expect(redis).to receive(:expire).with("requests:#{guid}", 5.minutes)
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

    context 'not authorized' do
      it 'return not_authorized status' do
        do_action
        expect(response.status).to eq 401
      end
    end
  end

  describe '#index' do
    let(:do_action) { get :index, params: { searchRequestId: guid } }

    context 'authorized' do
      before do
        allow_any_instance_of(PeopleController).to receive(:check_candidate_token).and_return true
        allow_any_instance_of(PeopleController).to receive(:current_candidate).and_return current_candidate
      end

      context "still 'processing'" do
        before do
          allow(redis).to receive(:get).with("requests:#{guid}:ttl").and_return([true])
        end

        it 'returns 102' do
          do_action
          expect(response.status).to eq 102
        end
      end
    end

    context 'not authorized' do
      it 'return not_authorized status' do
        do_action
        expect(response.status).to eq 401
      end
    end
  end
end
