# frozen_string_literal: true

File.readlines('db/people.json').each do |line|
  user = JSON.parse(line)
  User.create(uid:             user['id'],
              name:            user['name'],
              birthday:        user['birthday'].to_i,
              phone:           user['phone'],
              avatar:          user['avatar_origin'],
              email:           user['email'],
              quote:           user['quote'],
              chuck:           user['chuck'],
              address_street:  user['address']['street'],
              address_city:    user['address']['city'],
              address_country: user['address']['country'])
end
User.create(uid:             '12345',
            name:            'Wrongy McWrongface',
            birthday:        5.years.from_now,
            phone:           '1-800-not-here',
            avatar:          'http://www.trajectory4brands.com/wp-content/uploads/2016/09/Boaty.jpg',
            email:           'wrongy@mcwrongy.face',
            quote:           "I don't usually go wrong, but when I do its McWrongface",
            chuck:           'How much wood could Chuck Norris chuck if a Chu... All of it!',
            address_street:  '42 Main Street',
            address_city:    'Oopsala', # yes I know it is misspelled
            address_country: 'Country McLandface')
puts 'people imported'
