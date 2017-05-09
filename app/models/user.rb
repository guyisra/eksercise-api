# frozen_string_literal: true

class User < ApplicationRecord
  scope :by_name, ->(name) { where('name ILIKE ?', "%#{name}%") if name.present? }
  scope :by_age, ->(age) {
                   if age.present?
                     where('birthday > :upper_limit AND birthday <= :bottom_limit',
                           bottom_limit: age.to_i.years.ago.to_i,
                           upper_limit:  (age.to_i + 1).years.ago.to_i)
                   end
                 }
  scope :by_phone, ->(phone) { where('phone LIKE ?', "%#{phone}%") if phone.present? }

  scope :wrong, -> { where(uid: "12345") }

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
