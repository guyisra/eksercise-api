# frozen_string_literal: true

class User < ApplicationRecord
  def as_json(_)
    {
      'id'       => uid,
      'name'     => name,
      'phone'    => phone,
      'picture'  => avatar,
      'email'    => email,
      'birthday' => birthday,
      'address'  => {
        'city'    => address_city,
        'street'  => address_street,
        'country' => address_country
      }
    }
  end
end
