#!/usr/bin/ruby

Dir.chdir("/home/cmonkey")

require 'cspotrun_common'
include CspotrunCommon

puts "Hello from the shutdown script!"

send_message "shutting_down_now"
