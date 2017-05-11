class AddEvilThrottlingToCandidate < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :evil_throttling, :boolean, default: false
  end
end
