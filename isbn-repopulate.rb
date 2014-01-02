#!/usr/bin/ruby
#
# Rebuilds the isbn.db given a /tmp/x file containing
# tab delimited records
#
# /tmp/x is created with sqlite where the .mode is
# tabs
#
require 'rubygems'
require 'sqlite3'
require 'json'

`./isbn-init.rb`

db = SQLite3::Database.new("isbn.db")

lines = File.open("/tmp/x").readlines

rec_no = 1
lines.each {|x|
  x = x.chomp.split("\t")

  isbn = x[0]
  timestamp = x[1]
  used_price = x[2]
  in_media = x[3]

  puts "rec-no: #{rec_no}"
  rec_no = rec_no + 1
  puts "isbn : " + isbn
  lup = `./isbn-lookup.rb --api-mode #{isbn}`
  puts "lup: " + lup
  record = JSON.parse(lup)

  title = record.fetch("title", "").gsub("'", "`")
  author = record.fetch("author", "").gsub("'", "`")
  date_of_publication = record.fetch("date-of-publication", "")

    
  insert_stmt = 'insert into isbn(timestamp, isbn, used_price, in_media, title, author, date_of_publication) ' + 
  "VALUES('#{timestamp}', '#{isbn}', '#{used_price}', '#{in_media}', '#{title}', '#{author}', '#{date_of_publication}');"

  db.execute(insert_stmt)
}

db.close


