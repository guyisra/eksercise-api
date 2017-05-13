# frozen_string_literal: true

class Candidate < ApplicationRecord
  scope :not_expired, -> { where('created_at > ? ', 1.month.ago) }
end
