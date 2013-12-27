#!/usr/bin/ruby
#
require 'rubygems'
require 'sqlite3'


if ARGV.length < 1 then
  puts "clear-media-list <isbn> " 
  return
end

isbn_db = 'isbn.db'
isbn = ARGV[0]

db = SQLite3::Database.new(isbn_db)

max_media = db.get_first_value('select max(in_media)  from isbn;') + 1

if (isbn == 'all') then
  db.execute("update isbn set in_media = #{max_media} where in_media == 1")
else
  db.execute("update isbn set in_media = #{max_media} where isbn == '#{isbn}'")
end

db.close

