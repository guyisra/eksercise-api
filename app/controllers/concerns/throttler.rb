# frozen_string_literal: true

module Throttler
  THRESHOLD = 1

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
    current_ttl = redis.ttl(throttling_key).to_i
    redis.expire(throttling_key, current_ttl + Random.new.rand(5..10)) # tsk tsk, doesn't play nice
  end

  def handle_request
    if redis.incr(throttling_key).to_i == 1
      extend_cooldown
    end
  end
end
