#!/usr/bin/ruby
#
require 'rubygems'
require 'sqlite3'
require 'json'

isbn_db = "isbn.db"


db = SQLite3::Database.new(isbn_db)

h = []
db.execute("select isbn, author, title, used_price from isbn where in_media == 1") do | rec |
  h += [ { :isbn => rec[0], :author => rec[1], :title => rec[2] } ]
end

puts h.reverse.to_json


db.close
