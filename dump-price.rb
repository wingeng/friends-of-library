#!/usr/bin/env ruby
#
# Dumb script to dump sqlite data
#

script = <<END
.mode column
.width 15 15 35

attach "isbn.db" as db1;

select * from isbn  where used_price != \'\' order by used_price;
END

puts `echo "#{script}" > /tmp/sql-dump-price.sql`

puts `cat /tmp/sql-dump-price.sql | sqlite3 isbn.db`
