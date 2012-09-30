#!/usr/bin/ruby
#
require 'rubygems'
require 'sqlite3'

puts "isbn-insert <db> <isbn> <amazon-price>" if ARGV.length < 3

isbn_db = ARGV[0]
isbn_str = ARGV[1]
amazon_price = ARGV[2]


puts "isbn_str #{isbn_str} price #{amazon_price}"

db = SQLite3::Database.new(isbn_db)

insert_stmt = 'insert into isbn(timestamp, isbn, amazon_lowest_used_price) ' + 
  "VALUES(DateTime('now'), '#{isbn_str}', '#{amazon_price}');"

db.execute(insert_stmt)

db.close
