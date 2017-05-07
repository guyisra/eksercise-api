class AddEvilTogglesToCandidate < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :evil_long_response, :boolean, default: false
    add_column :candidates, :evil_expiry, :boolean, default: false
    add_column :candidates, :evil_malformed, :boolean, default: false
    add_column :candidates, :evil_wrong_results, :boolean, default: false
  end
end
