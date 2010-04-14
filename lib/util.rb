module Util
  
  require 'rubygems'
  require 'right_aws'
  require 'open3'
  
  
  def start_sdb
    sdb = RightAws::SdbInterface.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
    newdomain = sdb.create_domain(dbname())
    puts "newdomain:"
    pp newdomain
    puts "domains:"
    domains = sdb.list_domains
    pp domains
    return sdb
  end
  
  def dbname
    "cspotrun_#{RAILS_ENV}"
  end
  
  def run_cmd(cmd)
    stdin, stdout, stderr = Open3.popen3(cmd)
    pretty_stderr = pretty_stream(stderr)
    pretty_stdout = pretty_stream(stdout)
    error = pretty_stderr.empty?
    return pretty_stdout,pretty_stderr,error
  end
  
  def pretty_stream(stream)
    arr = stream.readlines#.map{|i|i.chomp}
    arr.join()
  end
  
  def latest_price(instance_type)
    puts "getting latest price for #{instance_type}"
    timestamp = aws_timestamp(Time.now)
    cmd = "ec2-describe-spot-price-history --instance-type #{instance_type} --start-time #{timestamp}"
    stdout,stderr,error = run_cmd(cmd)
    if error
      puts "oops, an error:"
      puts stderr
    else
      puts "result:"
      puts stdout
      lines = stdout.split("\n")
      for line in lines
        next if line.downcase =~ /windows/
        segs = line.split(/\s/)
        return segs[1].to_f
      end
      
    end
  end
  
  def recommended_price(current_price)
    current_price + 0.01
  end
  
  def aws_timestamp(timevar)
    utc = timevar.utc
     "#{utc.year}-#{"%02d" % utc.mon}-#{"%02d" % utc.mday}T#{"%02d" % utc.hour}:#{"%02d" % utc.min}:#{"%02d" % utc.sec}.000Z"
  end
  
  def spawn_job(job)
    # create init file
    
    
    manifest = {}
    manifest['job_id'] = job.id
    manifest['originating_host'] = `hostname`.chomp
    manifest['real_run'] = !job.is_test_run
    
    manifest_yaml = YAML::dump manifest
    
    File.open(job.user_data_file, "w") {|file| file.puts(manifest_yaml)}
    
    
    thread = Thread.new() do
      # do the rest of this stuff in a thread
      logger.info "hello from job submitting thread"
      fire_event("initializing cmonkey environment", job)
      args = {}
      args['organism'] = job.organism
      args['cmonkey.workdir'] = CMONKEY_WORKDIR
      args['ratios.file'] = job.ratios_file
      args['k.clust'] = job.k_clust
      args['parallel.cores'] = (job.instance_type == "m1.large") ? 2 : 8
      args['out.filename'] = "/tmp/initedEnv_#{job.id}.R"
      
      
      rdir = "#{RAILS_ROOT}/R"
      cmd = "R CMD BATCH -q --vanilla --no-save --no-restore '--args ARGS' #{rdir}/initenv.R #{rdir}/out"
      
      
      argstr = ""
      args.each_key do |key|
        value = args[key]
        value = %Q("#{value}") if value.respond_to?(:downcase)
        argstr += "#{key}=#{value} "
      end
      argstr.chop!
      
      cmd.gsub!("ARGS", argstr)
      
      logger.info "R command line:\n#{cmd}"
      
      stdout,stderr,error = run_cmd(cmd)

      fire_event("creating job bucket",job)
      
      
      job_bucket = create_job_bucket(job)
      
      fire_event("moving initial data to job bucket",job)
      
      move_data_to_job_bucket(job, job_bucket)
      
      fire_event("requesting instances",job)
      request_instances(job)
      
      fire_event("creating instance buckets",job)
      
      create_instance_buckets(job)
      
      
      
    end
    
  end

  def fire_event(text, job)
  end

  def create_job_bucket(job)
  end
  
  def move_data_to_job_bucket(job, job_bucket)
  end
  
  def request_instances(job)
  end
  
  def create_instance_buckets(job)
  end
  
  
end