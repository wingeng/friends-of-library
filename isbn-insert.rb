#!/usr/bin/ruby
#
require 'rubygems'
require 'sqlite3'
require 'json'

puts "isbn-insert <db> <isbn> " if ARGV.length < 2

isbn_db = ARGV[0]
isbn_str = ARGV[1]
insert_media = '0'
insert_media = '1' if ARGV.length > 2


lup = `cd ~wing/work/friends-o-library;./isbn-lookup.rb --api-mode #{isbn_str}`

record = JSON.parse(lup)

if record.fetch("return-code", "false") != "false" then

  title = record.fetch("title", "").gsub("'", "`")
  author = record.fetch("author", "").gsub("'", "`")
  price = record.fetch("price", "$0.00").gsub("$", "").to_f

  db = SQLite3::Database.new(isbn_db)

  insert_stmt = 'insert into isbn(timestamp, isbn, used_price, title, author, in_media) ' + 
    "VALUES(DateTime('now'), '#{isbn_str}', '#{price}', '#{title}', '#{author}', '#{insert_media}');"


  db.execute(insert_stmt)

  db.close

end

puts lup
