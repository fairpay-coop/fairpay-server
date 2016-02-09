# fairpay-server


## Prerequisites
* postgres 9.x  
* rvm 

## Getting started

```
$ git clone git@github.com:fairpay-coop/fairpay-server.git
$ cd fairpay-server
$ cp config/database-example.yml config/database.yml
$ bundle exec rake db:create db:migrate
$ bundle exec rails s
```

