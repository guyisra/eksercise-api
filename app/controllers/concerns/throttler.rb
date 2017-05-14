# frozen_string_literal: true

module Throttler
  THRESHOLD = 3

  def throttle!
    if over_threshold?
      extend_cooldown

      return redis.ttl(throttling_key)
    end

    handle_request
    return false
  end

  def throttling_key
    "throttling:#{guid}"
  end

  private

  def over_threshold?
    redis.get(throttling_key).to_i > THRESHOLD
  end

  def extend_cooldown
    redis.expire(throttling_key, Random.new.rand(5..10)) # tsk tsk, doesn't play nice
  end

  def handle_request
    if redis.incr(throttling_key).to_i == 1
      redis.expire(throttling_key, Random.new.rand(5..10))
    end
  end
end
