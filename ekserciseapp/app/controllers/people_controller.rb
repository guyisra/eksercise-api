# frozen_string_literal: true

class PeopleController < ApplicationController
  def search
    return head :method_not_allowed if invalid_request?

    guid = SecureRandom.uuid
    $redis.mapped_hmset("requests:#{guid}", req_data)
    $redis.set("requests:#{guid}:ttl", 'nope', px: Random.new.rand(1..777))

    render json: { id: guid }, status: 201
  end

  def index
    guid = params['searchRequestId']

    return head :processing if $redis.get("requests:#{guid}:ttl").present?

    req = $redis.hgetall("requests:#{guid}").symbolize_keys

    return head :not_found if req.empty?

    people = User.by_age(req[:age])
                 .by_name(req[:name])
                 .by_phone(req[:phone])
                 .page(req[:page] || 1)
                 .per(25)

    render json: people
  end

  private

  def invalid_request?
    req_data.except(:page).values.compact.blank?
  end

  def req_data
    {
      page:  params[:page] || 1,
      age:   params[:age],
      name:  params[:name],
      phone: params[:phone]
    }
  end
end
