#!/usr/bin/env ruby

require "rubygems"
require "mail"
require "json"

load 'smtp.config'

Mail.defaults do
  delivery_method :smtp, Options
end

output = JSON.parse(`cd ..;./isbn-list-in-media.rb`)

mail_body = ""
output.each {|rec|
  mail_body += rec["isbn"] + ", " + rec["author"] + ", " +  rec["title"] + "\n"
}

Mail.deliver do
  to MyConfig[:to]
  from MyConfig[:from]
  subject 'Media list'
  body mail_body
end

puts "Email sent to " + MyConfig[:to]

