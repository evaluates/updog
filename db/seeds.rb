# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#


Click.destroy_all

`curl -s --referer http://some-example.com/ http://jom.updog.co:3000/`
`curl -s --referer http://some-example.com/some-path http://jom.updog.co:3000/`
`curl -s --referer http://some-example.com/another-path http://jom.updog.co:3000/`

Stat.create(new_users: 4, new_upgrades: 0, percent_pro: 5.33333333333333, created_at: "2016-12-05 23:59:04", updated_at: "2016-12-05 23:59:04")
Stat.create(new_users: 8, new_upgrades: 1, percent_pro: 5.30355896720167, created_at: "2016-12-06 23:59:04", updated_at: "2016-12-06 23:59:04")
Stat.create(new_users: 6, new_upgrades: 0, percent_pro: 5.28144544822794, created_at: "2016-12-07 23:59:05", updated_at: "2016-12-07 23:59:05")
