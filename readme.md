# UpDog

[![Build Status](https://travis-ci.org/jshawl/updog.svg?branch=master)](https://travis-ci.org/jshawl/updog)

## Local Setup

    $ git clone git@github.com:jshawl/updog.git
    $ cd updog
    $ bundle install
    $ rake db:create
    $ rake db:migrate

Create a new file:

```ruby
# updog/config/application.yml

db_key: 'dropbox consumer key'
db_secret: 'dropbox consumer secret'
db_callback: 'http://localhost:3000/auth/dropbox/callback'
mailchimp_list_id: 'list id from mailchimp'
mailchimp_api_key: 'your mailchimp api key'
```
