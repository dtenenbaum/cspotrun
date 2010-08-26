#!/usr/bin/ruby

Dir.chdir("/home/cmonkey")



require './cspotrun_common'
include CspotrunCommon

send_message(ARGV.first)

