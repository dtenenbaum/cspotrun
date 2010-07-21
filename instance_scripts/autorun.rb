#!/usr/bin/ruby 

# autorun.rb script

Dir.chdir("/home/cmonkey")

require 'pp'
require 'rubygems'
require 'yaml'
require 'right_aws'

require './cspotrun_common'
include CspotrunCommon

login,password = credentials

puts "hello from the autorun.rb script!"
 
system("rm -f test_file")
system("touch test_file")

system("rm -f out")
system("rm metadata.yaml")
all_fields = `curl -s http://169.254.169.254/latest/meta-data/`
fields = all_fields.split("\n").reject{|i|i =~ /\/$/}
fields -= ['ancestor-ami-ids']
fields.sort!


metadata = {}


user_data = `curl -s http://169.254.169.254/latest/user-data`

uhash = {}
no_user_data = false

if (user_data.downcase =~ /404 - not found/)
  # we may have been started in the aws management console with no user data specified
 uhash = {}
 no_user_data = true
else
 uhash = YAML::load user_data
end

#user_data = "--- \nfoo: bar\n" # COMMENT THIS OUT SOON!
#uhash = YAML::load user_data
metadata['user_data'] = "none"
uhash.each_key do |key|
  metadata['user_data'] = "ok"
  metadata["user_data_" + key] = uhash[key]
end



for field in fields
  metadata[field] = `curl -s http://169.254.169.254/latest/meta-data/#{field}`
end


metadata['spot-instance-request-id'] = `curl -s http://baliga.systemsbiology.net/cgi-bin/get-sir-id.rb?instance-id=#{metadata['instance-id']}`

yaml_obj = YAML::dump metadata


File.open("metadata.yaml", "w") {|file| file.puts(yaml_obj) }

send_message("started node with no user data") if no_user_data

send_message "node_startup"

if (real_run?)
  puts "this is a real run"

  `rm -f cMonkey_latest.tar.gz`
  `rm -f #{TEMP}preinit.R`


  get_preinit_script()
  get_postproc_script()

  `wget http://baliga.systemsbiology.net/cmonkey/cMonkey_latest.tar.gz`
  # look for a bucket associated with this SIR
  job_bucket  = get_job_bucket()
  # if job_bucket is null, we should shut down

  instance_bucket = get_instance_bucket()
  # if instance_bucket is null, it might just mean it hasn't been created
  # but it should have been. if it does exist, we need to see if there is
  # partial data in it.
  puts "is instance bucket nil? #{instance_bucket.nil?}"
  if (does_bucket_have_file?(instance_bucket, "#{get_sir_id}/partial.RData"))
    process_data(instance_bucket, "#{get_sir_id}/partial.RData")
  else
    #send_message("no partial output found")
    process_data(job_bucket, "#{get_job_host}/job-#{get_job_id}/initedEnv.RData")
  end  
  send_finished_job
  send_log
  # make sure output file exists, then
 # shut down here
 if (job_complete?)
   send_message("cmonkey processing complete")
   shutdown()
 else
   send_state()
   send_message("error: cmonkey env file was not written! partial file saved. shutting down instance in 10 minutes!")
   sleep(10 * 60)
   shutdown()
 end
end 


