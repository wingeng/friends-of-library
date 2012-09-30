#!/usr/bin/ruby

require 'rubygems'
require 'asin'
require 'trollop'
require 'json'

Opts = Trollop::options do
  opt :api_mode, "API mode"
  opt :insert, "Insert found record"
end

#
# Use 'formic wars' if not found
#
ARGV[0] = "0765329042" if ARGV[0] == "example"

include ASIN::Client

def isbn_string(isbn_found, isbn, title = "", price = "", detail_page = "", image_set = "")
  if (Opts.api_mode)
    if (Opts.insert)
      `./isbn-insert.rb ./isbn.db #{isbn} #{price.gsub('$', '')}`
    end
    %Q{{
        "return-code" : "#{isbn_found}",
        "isbn" : "#{isbn}",
        "title" : "#{title}",
        "price" : "#{price}",
        "detail-page" : "#{detail_page}",
        "image-url" : "#{image_set}"
      }}
  else
    if (isbn_found) 
      "isbn: #{isbn} : #{title} : #{price}"
    else
      "isbn: #{isbn} : Not found"
    end
  end
end

def not_found(isbn)
  isbn_string(false, isbn)
end

#
# Load the amazon credentials.  The file should contain the following
# 
# ASIN::Configuration.configure do | config |
#   config.secret = ''
#   config.key = ''
#   config.associate_tag = ''
#   config.logger = nil
# end
#
load "asin-config.rb"


HTTPI.log = false

#
# Routine to dump the Mash object
#
def dump2(m, k, level, path)
  indent_str = 1.upto(level).map{|x| "   "}.join
  indent_str = level.to_s + indent_str

  if (m) then
    if (m.is_a?(Hashie::Mash)) then
      puts "#{indent_str} #{k} {"
      m.keys.each{|item|
        dump2(m[item], item, level + 1, path.push(item))
      }
      puts "#{indent_str} }"
    elsif (m.is_a?(String)) then
      puts "#{indent_str} #{path.last} = #{m}"
    else
      puts "#{indent_str} #{path.last} = #{m}"
    end
  end
end

def dump(m) 
  dump2(m, "", 0, [])
end

def lup(isbn)
  items = lookup(isbn, 
                 { :ResponseGroup => :Medium,
                   :IdType=> 'ISBN',
                   :SearchIndex=>'All'
                 })

  if (items == nil || items.length == 0) then
    return not_found(isbn)
  end

  #dump(items.first.raw)

  item = items.first
  isbn_string(true, isbn, item.title.gsub(":", "-").chomp,
              item.raw.OfferSummary.LowestUsedPrice.FormattedPrice,
              item.raw.DetailPageURL, item.raw.MediumImage.URL)

end


#lup('9781416595205')
#lup('9780981531649')

if ARGV.size > 0 then
  ARGV.each {|isbn|
    puts lup(isbn)
  }
  exit 0
end

if (STDIN.isatty) then
  puts ""
  puts "Enter ISBN one at a time to lookup used price"
  puts "Example:"
  puts "  isbn>  0765329042"
  puts "  Earth Unaware (Formic Wars) - $12.40"
  puts ""
  puts "Type 'q' to quit"
  puts ""
end


while (true) do
  printf("isbn > ") if (STDIN.isatty) 

  line = gets
  break if (line == nil)

  line = line.chomp
  break if (line == "q") 
  next if (line == "")
  
  puts lup(line)
  sleep(1) # throttle
end


