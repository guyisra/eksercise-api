class Candidate < ApplicationRecord

 scope :not_expired, -> { where("created_at > ? ", 2.months.ago)}
end
