source 'https://rubygems.org'
ruby "2.3.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.1'
# Use postgres as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'dotenv-rails' #, :groups => [:development, :test]
# could be enabled if needed
# gem 'dotenv-rails', :require => 'dotenv/rails-now'
# gem 'gem-that-requires-env-variables'


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Bulma as html/css foundation
gem "bulma-rails"

# Use devise for authentication
gem 'devise'

# Use slim for templating
gem 'slim-rails'

gem 'activeadmin', github: 'activeadmin'

# Use Grape/Swagger for the API endpoints
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-rails'

# payment processors
gem 'authorizenet'
# note the 'dwolla_swagger' version api looks like it's still half-baked
# gem 'dwolla_swagger', '~> 1.0', '>= 1.0.2'
gem 'dwolla_v2', '~> 0.2'

gem 'paypal-sdk-merchant'
# other paypal examples dependencies
gem 'haml'
gem 'simple_form'
# not compatible w/ rails 4
# gem 'merchant_samples', :git => "https://github.com/paypal/merchant-sdk-ruby.git", :group => :development


group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'seed-fu', '~> 2.3'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem "better_errors"
  gem "binding_of_caller"
end


gem 'rails_12factor', group: :production
