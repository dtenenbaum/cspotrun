#!/usr/bin/ruby

Dir.chdir("/home/cmonkey")

require 'pp'

require 'rubygems'
require 'right_aws'

require './cspotrun_common'
include CspotrunCommon

login, password = credentials

s3 = RightAws::S3.new(login,password)

#bucketname = 'isb-cspotrun-bootstrap'
bucketname = get_config['bootstrap_bucket_name']
bucket = s3.bucket(bucketname)

keys = bucket.keys

names = keys.map{|i|i.name}

names.sort!

puts names.join(",")

filewewant = names.last #assume it is a .tar.gz file

#key = bucket.get(filewewant)

puts "downloading #{filewewant}"

cmd = "/usr/local/s3sync/s3cmd.rb get #{bucketname}:#{filewewant} /tmp/latest.tar.gz"
`#{cmd}`

system("tar zxf /tmp/latest.tar.gz")
#system("rm /tmp/latest.tar.gz") # comment this?
FileUtils.rm_rf(TEMP)
FileUtils.mkdir(TEMP)
system("./autorun.rb")

