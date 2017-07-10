#!/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/bin/ruby
#!/usr/bin/ruby

require 'rubygems'
require 'asin'

include ASIN::Client


ASIN::Configuration.configure do | config |
  config.secret = 'xdM2bgPuQqr2N9+cmIDp32FJOOelR1vQShQrikLH'
  config.key = 'AKIAJO34C7OYTDQEDL3Q'
  config.associate_tag = 'wing05-20'
  config.logger = nil
end

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
  begin
    items = ASIN.lookup(isbn, 
                        { :ResponseGroup => :Medium,
                          :IdType=> 'ISBN',
                          :SearchIndex=>'Books'
                        })
  rescue Exception => e
    return isbn + " is having problems " + e
  end

  if (items == nil || items.length == 0) then
    return "#{isbn}: [#{isbn}] Not Found: "
  end

  item = items.first
  "%s: %s : %s\n" % [
         isbn,
         item.title.gsub(":", "-").chomp,
         item.raw.OfferSummary.LowestUsedPrice.FormattedPrice]
end


