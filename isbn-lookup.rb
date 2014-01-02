#!/usr/bin/ruby

require 'rubygems'
require 'asin'
require 'trollop'
require 'json'

Opts = Trollop::options do
  opt :api_mode, "API mode"
  opt :insert, "Insert found record"
  opt :dump, "Dump record"
end

#
# Use 'formic wars' if not found
#
ARGV[0] = "0765329042" if ARGV[0] == "example"

include ASIN::Client

#
# If item is an array, join string with ", "
# otherwise just to_s
# 
def to_joined_str (item)
  if (item.class == Array) then
    item.join(", ")
  else
    item.to_s
  end
end

#
# Returns the first non-nil item in list
#
def one_of(*args)
  args.each {|x|
    return to_joined_str(x) if x
  }

  ""
end

def isbn_string(isbn_found, isbn, rec)
  if (Opts.api_mode)
    if (Opts.insert)
      `./isbn-insert.rb ./isbn.db #{isbn}`
    end

    %Q{{
        "return-code" : "#{isbn_found}",
        "isbn" : "#{isbn}",
        "title" : "#{one_of(rec[:title])}",
        "author" : "#{one_of(rec[:author])}",
        "price" : "#{one_of(rec[:price])}",
        "detail-page" : "#{one_of(rec[:detail_page])}",
        "image-url" : "#{one_of(rec[:image_set])}",
        "date-of-publication" : "#{one_of(rec[:date_of_publication])}"
      }}
  else
    if (isbn_found) 
      "isbn: #{isbn} : #{rec[:author]} : #{rec[:title]} : #{rec[:price]} : #{rec[:date_of_publication]}"
    else
      "isbn: #{isbn} : Not found"
    end
  end
end

def not_found(isbn)
  isbn_string(false, isbn, {})
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

def lup_inner(isbn)
  retry_time = 0.2

  items = ""
  while retry_time do
    begin
      items = lookup(isbn, 
                     { :ResponseGroup => :Medium,
                       :IdType=> 'ISBN',
                       :SearchIndex=>'All'
                     })

      if (items == nil || items.length == 0) then
        items = lookup(isbn, 
                       { :ResponseGroup => :Medium,
                         :IdType=> 'UPC',
                         :SearchIndex=>'All'
                       })

      end
      retry_time = nil
    rescue Exception => e
      if (e.to_s == "request failed with response-code='503'") then
        STDERR.puts("sleeping #{retry_time}")
        sleep(retry_time)
        retry_time = retry_time * 2
      else
        puts "Unknown error: e = '#{e}'"
        break
      end
    end

  end

  items
end

def lup(isbn)
  # lookup with exponential backup

  items = lup_inner(isbn)

  if (items == nil || items.length == 0) then
    return not_found(isbn)
  end

  if (Opts.dump) then
    dump(items.first.raw)
  end

  item = items.first

  if item.raw.OfferSummary.LowestUsedPrice then
    price = item.raw.OfferSummary.LowestUsedPrice.FormattedPrice
  else
    price = "$0.00"
  end

  if item.raw.MediumImage then
    image_set = item.raw.MediumImage.URL
  else
    image_set = ""
  end

  author = one_of(item.raw.ItemAttributes.Author,
                  item.raw.ItemAttributes.Artist,
                  item.raw.ItemAttributes.Creator,
                  "")
  rec = {}
  rec[:title] = item.title.gsub(":", "-").gsub('"', "").chomp
  rec[:author] = author
  rec[:price] = price
  rec[:detail_page] = item.raw.DetailPageURL
  rec[:image_set] = image_set
  rec[:date_of_publication] = one_of(item.raw.ItemAttributes.PublicationDate,
                                     item.raw.ItemAttributes.ReleaseDate,
                                     "date-not-found")

  isbn_string(true, isbn, rec)

end


#lup('9781416595205')
#lup('9780981531649')

if ARGV.size > 0 then
  ARGV.each {|isbn|
    ret = lup(isbn)
    puts ret if ret
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


