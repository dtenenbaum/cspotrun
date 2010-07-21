#!/usr/bin/ruby


t = Time.new

timestamp = t.strftime("%Y%m%d_%H%M")
outfile = "#{timestamp}.tar.gz"
puts "taking a snapshot as #{outfile}..."
#system("rm -f  *.pdf")
system("tar zcf /tmp/#{outfile} .")
system("s3cmd.rb put isb-cspotrun-bootstrap:#{outfile} /tmp/#{outfile}")
system("rm -f /tmp/#{outfile}")
