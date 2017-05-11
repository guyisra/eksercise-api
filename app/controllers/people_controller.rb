# frozen_string_literal: true

class PeopleController < ApplicationController
  before_action :check_candidate_token
  before_action :evil_long_response

  before_action :evil_throttling, only: :index

  def search
    return head :method_not_allowed if invalid_request?

    request_token = SecureRandom.uuid
    store_req_data(request_token)

    render json: { id: request_token }, status: 201
  end

  def index
    return head :processing if guid_processing

    req = redis.hgetall("requests:#{guid}").symbolize_keys

    return head :not_found if req.empty?

    people = User.by_age(req[:age])
                 .by_name(req[:name])
                 .by_phone(req[:phone])
                 .page(req[:page] || 1)
                 .per(25)

    render json: evil_answer(people)
  end

  private

  def guid
    params['searchRequestId']
  end

  def store_req_data(request_token)
    redis.mapped_hmset("requests:#{request_token}", req_data)
    redis.expire("requests:#{request_token}", 5.minutes)
    redis.set("requests:#{request_token}:ttl", 'nope', px: Random.new.rand(1000..7777))
  end

  def guid_processing
    redis.get("requests:#{guid}:ttl").present?
  end

  def invalid_request?
    req_data.except(:page).values.compact.blank?
  end

  def current_candidate
    Candidate.find_by_key(request.headers['X-KLARNA-TOKEN'])
  end

  def req_data
    {
      page:  params[:page] || '1',
      age:   params[:age],
      name:  params[:name],
      phone: params[:phone]
    }
  end

  def check_candidate_token
    return head :unauthorized unless Candidate.not_expired
                                              .where(
                                                key: request.headers['X-KLARNA-TOKEN']
                                              ).present?
  end

  def evil_answer(people)
    if current_candidate.evil_wrong_results?
      people = if people.blank?
                 User.wrong
               else
                 people.or(User.wrong)
               end
    end

    people = malform(people) if current_candidate.evil_malformed? && people.present?

    people
  end

  def malform(people)
    people.to_json.insert(42, JSON.parse(Net::HTTP.get(URI('http://hipsterjesus.com/api/?paras=1&html=false')))['text'])
  end

  def evil_long_response
    sleep 45.seconds if current_candidate.evil_long_response?
  end

  def evil_throttling
    return unless current_candidate.evil_throttling?

    throttling_key = "throttling:#{guid}"

    if redis.get(throttling_key).to_i > 3
      redis.expire(throttling_key, Random.new.rand(5..10)) # tsk tsk, doesn't play nice

      return head :too_many_requests, retry_after: redis.ttl(throttling_key)
    end
    redis.expire(throttling_key, Random.new.rand(5..10)) if redis.incr(throttling_key).to_i == 1
  end
end
