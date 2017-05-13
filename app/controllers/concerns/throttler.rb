# frozen_string_literal: true

module Throttler
  def throttle!
    if over_threshold?
      redis.expire(throttling_key, Random.new.rand(5..10)) # tsk tsk, doesn't play nice

      return head :too_many_requests, retry_after: redis.ttl(throttling_key)
    end

    handle_request
  end

  private

  def throttling_key
    "throttling:#{guid}"
  end

  def over_threshold?
    redis.get(throttling_key).to_i > 3
  end

  def handle_request
    if redis.incr(throttling_key).to_i == 1
      redis.expire(throttling_key, Random.new.rand(5..10))
    end
  end
end
