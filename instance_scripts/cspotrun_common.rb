# this override works, but not from within the module below!
# todo fix
class Hash
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|   # <-- here's my addition (the 'sort')
          map.add( k, v )
        end
      end
    end
  end
end



module CspotrunCommon


  require 'yaml'
  require 'pp'
  require 'rubygems'
  require 'right_aws'
  require 'socket'
  TEMP = "/home/cmonkey/tmp"


  #puts "in common module"
  def credentials()
    credentials = YAML.load_file("#{home}/.s3conf/s3config.yml")
    [credentials['aws_access_key_id'],credentials['aws_secret_access_key']]    
  end
  
  def s3cmd_home()
    "/usr/local/s3sync"
  end
  def home()
    "/home/cmonkey"
  end
  def r_home()
    "/usr/bin"
  end

  def get_metadata()
    metadata = YAML.load_file("#{home}/metadata.yaml")
  end

  def login()
    login, password = credentials
    s3 = RightAws::S3.new(login,password)
  end

  def get_job_id
    metadata = get_metadata()
    metadata['user_data_job_id']
  end

  def get_sir_id
    metadata = get_metadata()
    metadata['spot-instance-request-id']
  end

  
  def get_job_host
    metadata = get_metadata()
    host = safe_bucket_name(metadata['user_data_originating_host'])
    host.split(".").first
  end

  def get_job_bucket
    get_bucket("isb-cspotrun-job-bucket")
  end

  def get_job_bucket_old()
    metadata = get_metadata()
    id = metadata['user_data_job_id']
    host = safe_bucket_name(metadata['user_data_originating_host'])
    name = "isb-cspotrun-job-bucket-#{host}-#{id}"
    puts "looking for job bucket with name #{name}"
    if id  == 'none'
      send_message("no job bucket found (user-data not defined)!")
      return nil
    end
    bucket = get_bucket(name)
    send_message("no job bucket found") if bucket.nil?
    bucket
  end

  def get_instance_bucket
    get_bucket("isb-cspotrun-instance-bucket")
  end

  
  def  get_instance_bucket_old()
    metadata = get_metadata()
    name = "isb-cspotrun-instance-bucket-#{metadata['spot-instance-request-id']}"
    puts "looking for bucket with name #{name}"
    if name.nil? or name.empty? or name == 'not found'
      send_message("no instance bucket found (spot-instance-request-id not defined)!")
      return nil
    end
    puts "instance bucket is called #{name}"
    bucket = get_bucket(name)
    send_message("no instance bucket found") if bucket.nil?
    bucket
  end

  def get_bucket(name)
    metadata = get_metadata()
    s3 = login
    bucket = s3.bucket(name)
  end


  def send_message(message)
    login, password = credentials()
    sqs = RightAws::SqsGen2.new(login,password)
    queue1 = sqs.queue("cspotrun-from-instances")
    message = (message.nil? or message.empty?) ? "empty message" : message
    metadata = get_metadata()
    metadata['message'] = message
    queue1.send_message(metadata.to_yaml)
#    puts "sent message: #{metadata.to_yaml}"
    puts "sent message: #{message}"
  end
  
  def real_run?
    metadata = get_metadata()
    metadata['user_data_real_run'] == true
  end

 # todo modify to use right_aws instead of cgi
 def cancel_request()
    metadata = get_metadata()
    cmd = "curl -s http://baliga.systemsbiology.net/cgi-bin/cancel-instance-request.rb?sir-id=#{metadata['spot-instance-request-id']}"
   send_message("cancelling instance request")
   `#{cmd}`
    
 end

 # use right_aws instead of cgi
 def terminate_instance()
   metadata = get_metadata()
   cmd = "curl -s http://baliga.systemsbiology.net/cgi-bin/terminate-instance.rb?instance-id=#{metadata['instance-id']}"
#   cmd += "something"
   puts cmd
   send_message("terminating instance")
   response =`#{cmd}` 
   puts response
 end
 
 def shutdown()
   cancel_request
   terminate_instance
   exit
 end

 def does_bucket_have_file?(bucket, file)
  for key in bucket.keys
    return true if key.to_s == file
  end
  return false
 end

 def get_preinit_script()
  bucket = get_job_bucket()
  if (does_bucket_have_file?(bucket, "#{get_job_host}/job-#{get_job_id}/preinit.R"))
    send_message("getting preinitialization script")
    cmd = "#{s3cmd_home}/s3cmd.rb get #{bucket.to_s}:#{get_job_host}/job-#{get_job_id}/preinit.R #{datapath}/preinit.R"
    `#{cmd}`      
  else
    send_message("no preinitialization script supplied")
  end
 end

 def get_postproc_script()
  bucket = get_job_bucket()
  if (does_bucket_have_file?(bucket, "#{get_job_host}/job-#{get_job_id}/postproc.R"))
    send_message("getting postprocessing script")
    cmd = "#{s3cmd_home}/s3cmd.rb get #{bucket.to_s}:#{get_job_host}/job-#{get_job_id}/postproc.R #{datapath}/postproc.R"
    `#{cmd}`
  else
    send_message("no postprocessing script supplied")
  end
 end

 def process_data(bucket, file)
   puts "in process_data()"
   cmd = "#{s3cmd_home}/s3cmd.rb get #{bucket.to_s}:#{file} #{datapath}/env.RData"
   puts "#{cmd}"
   `#{cmd}`
   cmd = "#{r_home}/R CMD BATCH --no-save --no-restore #{home}/cmRunner.R #{datapath}/out"    
   puts "R cmd = \n#{cmd}"
   `#{cmd}`
 end

 def send_state(file=nil) 
   b = get_instance_bucket()
   name = b.to_s
   cmd = "#{s3cmd_home}/s3cmd.rb put #{name}:#{get_sir_id}/partial.RData #{datapath}/partial.RData" 
   `#{cmd}`
   send_log
 end

 def send_log()
  name = get_instance_bucket.to_s
  cmd = "touch #{datapath}/out;cp #{datapath}/out #{datapath}/cmonkey.log.txt;gzip -f #{datapath}/cmonkey.log.txt;#{s3cmd_home}/s3cmd.rb put #{name}:#{get_sir_id}/cmonkey.log.txt.gz #{datapath}/cmonkey.log.txt.gz"
#  puts "log backup command = \n#{cmd}"
  `#{cmd}`
 end 

 def send_finished_job
   b = get_instance_bucket
   name = b.to_s
   cmd = "#{s3cmd_home}/s3cmd.rb put #{name}:#{get_sir_id}/complete.image.RData #{datapath}/complete.image.RData"
   `#{cmd}`

 end
	
  def datapath
    TEMP
  end

  def safe_bucket_name(name)
    name.downcase.gsub("_","-")
  end
  
  def job_complete?()
   name = "#{datapath}/complete.image.RData"
   exists = test(?f, name) 
   if exists
     size = test(?s, name)
     return true unless size.nil?
   end
   false
  end


def local_ip
  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

  UDPSocket.open do |s|
    s.connect '64.233.187.99', 1
    s.addr.last
  end
ensure
  Socket.do_not_reverse_lookup = orig
end

def get_random_seed
  local_ip.hash + Time.now.to_i
end

end
