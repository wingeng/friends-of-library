#!/usr/bin/ruby
#
# Script used to create the table for ISBN data
#

require 'rubygems'
require 'sqlite3'

db = SQLite3::Database.new("isbn.db")

db.execute("DROP TABLE isbn;")
db.execute("CREATE TABLE isbn (
                id integer primary key autoincrement,
                isbn text key,
                timestamp time,
                used_price string,
                title text,
                author string,
                in_media integer,
                date_of_publication time
);")

db.close
