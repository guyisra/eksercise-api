File.readlines('db/people.json').each do |line|
  user = JSON.parse(line)
  User.create(uid: user['id'],
              name: user['name'],
              birthday: user['birthday'].to_i,
              phone: user['phone'],
              avatar: user['avatar_origin'],
              email: user['email'],
              quote: user['quote'],
              chuck: user['chuck'],
              address_street: user['address']['street'],
              address_city: user['address']['city'],
              address_country: user['address']['country'])
end
puts 'people imported'
