class RemoveEvilExpiryColumn < ActiveRecord::Migration[5.0]
  def change
    remove_column :candidates, :evil_expiry
  end
end
