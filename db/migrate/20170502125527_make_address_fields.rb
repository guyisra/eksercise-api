class MakeAddressFields < ActiveRecord::Migration[5.0]
  def change
   remove_column :users, :address
   add_column :users, :address_street, :string
   add_column :users, :address_city, :string
   add_column :users, :address_country, :string
  end
end
