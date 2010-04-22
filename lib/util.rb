module Util
  
  require 'rubygems'
  require 'right_aws'
  require 'open3'
  
  #unless (defined?(logger))
  #  logger.info "Setting logger"
  #  ##logger = Rails.logger
  #  logger = RAILS_DEFAULT_LOGGER
  #end
  
  def logger
    Rails.logger
  end
  
  def self.atest
    logger.info "a test"
  end
  
  
  def do_nothing
    logger.info "does this count as nothing?"
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
    logger.info "getting latest price for #{instance_type}"
    timestamp = aws_timestamp(Time.now)
    cmd = "ec2-describe-spot-price-history --instance-type #{instance_type} --start-time #{timestamp}"
    stdout,stderr,error = run_cmd(cmd)
    if error
      logger.info "oops, an error:"
      logger.info stderr
    else
      logger.info "result:"
      logger.info stdout
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
    logger.info "in spawn_job"
    
    fire_event("spawning init job", job)
    
    manifest = {}
    manifest['job_id'] = job.id
    manifest['originating_host'] = `hostname`.chomp
    manifest['real_run'] = !job.is_test_run
    
    manifest_yaml = YAML::dump manifest
    
    File.open(job.user_data_file, "w") {|file| file.puts(manifest_yaml)}
    
    
   ## thread = Thread.new() do
      # do the rest of this stuff in a thread
      logger.info "hello from job submitting thread"
      logger.info "hello from job submitting thread"
      fire_event("initializing cmonkey environment", job)
      args = {}
      args['organism'] = job.organism
      args['cmonkey.workdir'] = CMONKEY_WORKDIR
      args['ratios.file'] = job.ratios_file
      args['k.clust'] = job.k_clust
      args['parallel.cores'] = (job.instance_type == "m1.large") ? 2 : 8
      args['out.filename'] = "/tmp/initedEnv_#{job.id}.RData"
      args['n.iter'] = job.n_iter
      
      
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
      
      
      system("rm -f #{rdir}/out")
      stdout,stderr,error = run_cmd(cmd)
      
      logger.info "stdout from r init job:\n#{stdout}"
      logger.info "stderr from r init job:\n#{stderr}" if error
      
      
      
      begin
        #include Util #if RAILS_ENV == 'development'
        fire_event("creating job bucket", job)
        job_bucket = create_job_bucket(job)


        fire_event("moving initial data to job bucket",job)

        move_data_to_job_bucket(job, job_bucket)

        fire_event("requesting instances",job)
        request_instances(job)

        fire_event("creating instance buckets",job)

        create_instance_buckets(job)

      rescue Exception => ex
        logger.info ex.message
        logger.info ex.backtrace
      end

      
      
    ##end
    
  end

  def fire_event(text, job, instance_name=nil)
    id  = (job.is_a?(Fixnum)) ? job : job.id
    
    instance_id = nil

    unless (instance_name.nil?)
      instance = Instance.find_by_sir_id(instance_name)
      instance_id = instance.id unless instance.nil?
    end

    logger.info "firing event: #{text} on job #{id}, instance_id = #{instance_id}"

    
    e = Event.new(:text => text, :job_id => id, :instance_id => instance_id)
    e.save
  end
  
  def utiltest
    logger.info "in test"
  end
  
  def get_job_bucket_name(job)
    hostname = safe_bucket_name(`hostname`.chomp())
    "cspotrun-job-bucket-#{hostname}-#{job.id}"
  end

  def create_job_bucket(job)
    create_bucket(get_job_bucket_name(job))
  end
  
  def create_bucket(name)
    logger.info "Creating bucket #{name}"
    cmd = "s3cmd.rb createbucket #{name}"
    stdout, stderr, error = run_cmd(cmd)
    if (error)
      logger.info "stderr output creating bucket:\n#{stderr}"
    end
  end
  
  def move_data_to_job_bucket(job, job_bucket)
    cmd = "s3cmd.rb put #{get_job_bucket_name(job)}:initedEnv.RData /tmp/initedEnv_#{job.id}.RData"
    stdout, stderr, error = run_cmd(cmd)
    if (error)
      logger.info "stderr output moving data to job bucket:\n#{stderr}"
    end
  end
  
  def request_instances(job)
    cmd = job.command
    stdout, stderr, error = run_cmd(cmd)
    if (error)
      logger.info "stderr output requesting instances:\n#{stderr}"
    end
    lines = stdout.split("\n")
    for line in lines
      #SPOTINSTANCEREQUEST     sir-bac91c04    0.127   persistent      Linux/UNIX     open     2010-04-15T11:15:17-0800                                               ami-35c02e5c     m1.large        gsg-keypair     default
      segs = line.split(/\s/)
      i = Instance.new(:job_id => job.id, :sir_id => segs[1])
      i.save
      fire_event("creating instance #{i.sir_id}", job)
    end
    
  end
  
  def create_instance_buckets(job)
    for instance in job.instances
      name = "cspotrun-instance-bucket-#{instance.sir_id}"
      create_bucket(name)
      fire_event("creating instance bucket #{name}", job)
    end
  end
  
  def safe_bucket_name(name)
    name.downcase.gsub("_","-")
  end
  
  
end