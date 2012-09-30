#!/usr/bin/ruby
#
# Script used to create the table for ISBN data
#

require 'rubygems'
require 'sqlite3'

db = SQLite3::Database.new("isbn.db")

db.execute("CREATE TABLE isbn (
                timestamp time primary key,
                isbn text,
                amazon_lowest_used_price string);")
