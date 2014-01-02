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
  mail_body += "isbn:     #{rec["isbn"]}\n"
  mail_body += "title:    #{rec["title"]}\n"
  mail_body += "author:   #{rec["author"]}\n"
  mail_body += "pub-date: #{rec["date_of_publication"].to_s}\n"
  mail_body += "\n"
}

Mail.deliver do
  to MyConfig[:to]
  from MyConfig[:from]
  cc MyConfig[:cc]
  subject 'Media list'
  body mail_body
end

puts "Email sent to " + MyConfig[:to]

