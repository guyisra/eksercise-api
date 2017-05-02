class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :uid
      t.string :name
      t.integer :birthday
      t.string :phone
      t.string :address
      t.string :avatar
      t.string :email
      t.string :quote
      t.string :chuck

      t.timestamps null: false
    end
  end
end
