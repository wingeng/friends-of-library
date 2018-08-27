#!/usr/bin/env ruby

require "rubygems"
require "mail"
require "json"

output = JSON.parse(`./isbn-list-in-media.rb`)

output.each {|rec|
  puts "'#{rec["title"]}', '#{rec["author"]}', '#{rec["date_of_publication"].to_s}'"
}

