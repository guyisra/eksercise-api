# frozen_string_literal: true

class PeopleController < ApplicationController
  before_action :check_candidate_token

  before_action :evil_long_response

  def search
    return head :method_not_allowed if invalid_request?

    guid = SecureRandom.uuid
    store_req_data(guid)

    render json: { id: guid }, status: 201
  end

  def index
    guid = params['searchRequestId']

    return head :processing if guid_processing(guid)

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

  def store_req_data(guid)
    redis.mapped_hmset("requests:#{guid}", req_data)
    redis.expire("requests:#{guid}", evil_query_expiry)
    redis.set("requests:#{guid}:ttl", 'nope', px: Random.new.rand(1..777))
  end

  def guid_processing(guid)
    redis.get("requests:#{guid}:ttl").present?
  end

  def invalid_request?
    req_data.except(:page).values.compact.blank?
  end

  def current_candidate
    Candidate.find_by_key(request.headers['HTTP_API_KEY'])
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
    sleep Random.new.rand(5..15).seconds if current_candidate.evil_long_response?
  end

  def evil_query_expiry
    if current_candidate.evil_expiry?
      Random.new.rand(1..5).seconds
    else
      5.minutes
    end
  end
end
