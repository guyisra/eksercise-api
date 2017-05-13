# frozen_string_literal: true

require 'rails_helper'

describe PeopleController do
  let(:guid) { '12345' }
  let(:redis) { double(:redis) }
  let(:req_params) { { age: '7', name: 'me', phone: '638-2020' } }
  let(:evil_long_response) { false }
  let(:evil_malformed) { false }
  let(:evil_wrong_results) { false }
  let(:evil_throttling) { false }
  let(:current_candidate) do
    Candidate.create(name:               'Candy',
                     key:                '12345',
                     evil_long_response: evil_long_response,
                     evil_malformed:     evil_malformed,
                     evil_wrong_results: evil_wrong_results,
                     evil_throttling:    evil_throttling)
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
      let(:base_params) do
        {}
      end
      let(:request_params) { base_params }
      before do
        allow_any_instance_of(PeopleController).to receive(:check_candidate_token).and_return true
        allow_any_instance_of(PeopleController).to receive(:current_candidate).and_return current_candidate
        allow(redis).to receive(:get).with("requests:#{guid}:ttl").and_return(nil)
        allow(redis).to receive(:hgetall).and_return(request_params)
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

      context 'return results' do
        let(:name) { 'Mike' }
        let(:age) { '30' }
        let(:phone) { '555' }
        let(:page) { '1' }

        context 'by name' do
          let(:request_params) { base_params.merge(name: name) }
          before do
            User.create(uid: 'name', name: name)
          end

          it 'returns the user' do
            do_action

            expect(JSON.parse(response.body)).to include(hash_including({ 'id' => 'name', 'name' => name }))
          end
        end

        context 'by age' do
          let(:request_params) { base_params.merge(age: age) }
          before do
            User.create(uid: 'name', birthday: 30.years.ago.to_i)
          end

          it 'returns the user' do
            do_action

            expect(JSON.parse(response.body)).to include(hash_including({ 'id' => 'name', 'birthday' => 30.years.ago.to_i }))
          end
        end

        context 'by phone' do
          let(:request_params) { base_params.merge(phone: phone) }
          before do
            User.create(uid: 'name', phone: '555-12345')
          end

          it 'returns the user' do
            do_action

            expect(JSON.parse(response.body)).to include(hash_including({ 'id' => 'name', 'phone' => '555-12345' }))
          end
        end

        context 'by page' do
          before do
            26.times do
              User.create(uid: 'name', phone: '555-12345')
            end
          end

          context 'first page' do
            let(:request_params) { base_params.merge(page: 1, phone: phone) }
            it 'returns 25 results' do
              do_action

              expect(JSON.parse(response.body).size).to eq 25
            end
          end

          context 'not first page' do
            let(:request_params) { base_params.merge(page: 2, phone: phone) }

            it 'returns the user' do
              do_action

              expect(JSON.parse(response.body)).to include(hash_including({ 'id' => 'name', 'phone' => '555-12345' }))
              expect(JSON.parse(response.body).size).to eq 1
            end
          end
        end
      end

      context 'evil things' do
        let(:request_params) { base_params.merge(name: 'Jim') }
        before do
          allow(redis).to receive(:get).with("requests:#{guid}:ttl").and_return(nil)
          allow(redis).to receive(:hgetall).and_return(request_params)
          User.create(name: 'Jim')
        end
        context 'evil malform' do
          let(:evil_malformed) { true }

          (0..4).to_a.each do |method|
            it 'returns a malformed unparsable response' do
              allow_any_instance_of(Random).to receive(:rand).and_return(method)

              do_action
              expect { JSON.parse(response.body) }.to raise_error JSON::ParserError
            end
          end
        end

        context 'evil long response' do
          let(:evil_long_response) { true }
          it 'sleeps' do
            allow_any_instance_of(Object).to receive(:sleep).with(45.seconds).and_return true

            do_action
          end
        end

        context 'evil throttling' do
          let(:evil_throttling) { true }

          it 'throttles' do
            allow_any_instance_of(described_class).to receive(:throttle!)

            do_action
          end
        end

        context 'evil wrong results' do
          let(:evil_wrong_results) { true }
          before do
            User.create(uid: '12345', name: 'WRONG!!')
          end

          it 'return a wrong result' do
            do_action

            expect(JSON.parse(response.body)).to include(hash_including(
                                                           'id'   => '12345',
                                                           'name' => 'WRONG!!'
            ))
          end
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
