# what is best way to bootstrap new db's?  fixtures/seeds.rb doesn't seem to be used
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password')
