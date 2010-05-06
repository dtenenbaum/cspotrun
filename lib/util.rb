module Util
  
  require 'rubygems'
  require 'right_aws'
  require 'open3'
  require 'systemu'
  require 'yaml'
  
  
  def logger
    Rails.logger
  end
  
  def self.atest
    lputs "a test"
  end
  
  def rc(cmd)
    #ec2-describe-spot-price-history --instance-type c1.xlarge --start-time 2008-05-04T13:53:45-0800 -d Linux/UNIX
  end
  
  def do_nothing
    lputs "does this count as nothing?"
  end
  
  def run_cmd(cmd)
    safecmd = cmd.gsub(CSPOTRUN_PASS, "--secret-password--")
    lputs "in run_cmd(), running command:\n#{safecmd}"
    #stdin, stdout, stderr = Open3.popen3(cmd)
    status, stdout, stderr = systemu(cmd)
    #pretty_stderr = pretty_stream(stderr)
    #pretty_stdout = pretty_stream(stdout)
    #error = pretty_stderr.empty?
    error = stderr.empty?
    #return pretty_stdout,pretty_stderr,error,status
    return stdout, stderr, error, status
  end
  
  def pretty_stream(stream)
    arr = stream.readlines#.map{|i|i.chomp}
    arr.join()
  end
  
  
  def latest_price()
    timestamp = aws_timestamp(Time.now)
    result = EC2.describe_spot_price_history(:start_time => Time.now, :instance_types => ["c1.xlarge","m1.large"], :product_description => "Linux/UNIX")
    c1_xlarge = 0.0
    m1_large = 0.0
    for item in result
      if (item[:instance_type] == 'c1.xlarge')
        c1_xlarge = item[:spot_price]
      end
      if(item[:instance_type] == 'm1.large')
        m1_large = item[:spot_price]
      end
    end
    pp result
    return c1_xlarge, m1_large
  end
  
  def latest_price_viejo(instance_type)
    timestamp = aws_timestamp(Time.now)
    url = "http://baliga.systemsbiology.net/cgi-bin/get-pricing-info.rb?instance-type=#{instance_type}&start-time=#{timestamp}"
    cmd = "curl -s \"#{url}\""
    stdout,stderr,error = run_cmd(cmd)
    if error
      lputs "oops, an error:"
      lputs stderr
    end
    lputs "result:"
    lputs stdout
    lines = stdout.split("\n")
    for line in lines
      next if line.downcase =~ /windows/
      segs = line.split(/\s/)
      return segs[1].to_f
    end
  end
  
  def latest_price_old(instance_type)
    lputs "getting latest price for #{instance_type}"
    timestamp = aws_timestamp(Time.now)
    cmd = "#{EC2_TOOLS_HOME}ec2-describe-spot-price-history --instance-type #{instance_type} --start-time #{timestamp}"
    #stdout = `#{cmd}`
    #error = false
    stdout,stderr,error = run_cmd(cmd)
    if error
      lputs "oops, an error:"
      lputs stderr
    else
      lputs "result:"
      lputs stdout
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
  
  
  def lputs(message)
    puts message
    logger.info message
  end
  
  def spawn_job(job)
    # create init file
    lputs "in spawn_job"
    
    fire_event("spawning init job", job)
    
    manifest = {}
    manifest['job_id'] = job.id
    manifest['originating_host'] = `hostname`.chomp
    manifest['real_run'] = !job.is_test_run
    
    manifest_yaml = YAML::dump manifest
    
    File.open(job.user_data_file, "w") {|file| file.puts(manifest_yaml)}
    
    
   ## thread = Thread.new() do
      # do the rest of this stuff in a thread
      lputs "hello from job submitting thread"
      
      if (job.user_supplied_rdata)
        # no need to run R, we have a preinitialized RData file
      else
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
        cmd = "#{R_LOC}R CMD BATCH -q --vanilla --no-save --no-restore '--args ARGS' #{rdir}/initenv.R /tmp/initenv_#{job.id}.out"


        argstr = ""
        args.each_key do |key|
          value = args[key]
          value = %Q("#{value}") if value.respond_to?(:downcase)
          argstr += "#{key}=#{value} "
        end
        argstr.chop!

        cmd.gsub!("ARGS", argstr)

        lputs "R command line:\n#{cmd}"


        #system("rm -f #{rdir}/out")
        stdout,stderr,error,status = run_cmd(cmd)
        #todo - see if there was an error initializing the RData file and if so, tell the user and abort. there is no point continuing.

        lputs "stdout from r init job:\n#{stdout}"
        lputs "stderr from r init job:\n#{stderr}" if error
        lputs "status from r init job:\n#{status}"
        if (status.exited? and status.exitstatus != 0)
          fire_event("error:error initializing RData file!", job)
          return
        end
      end
      
      
      ##### return if true #####
      
      
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
        lputs "done with spawning job #{job.id}"

      rescue Exception => ex
        lputs ex.message
        lputs ex.backtrace
      end

      
      
    ##end
    
  end

  def fire_event(text, job, instance_name=nil, public_ip=nil)
    id  = (job.is_a?(Fixnum)) ? job : job.id
    
    instance_id = nil

    unless (instance_name.nil?)
      instance = Instance.find_by_sir_id(instance_name)
      instance_id = instance.id unless instance.nil?
    end

    lputs "firing event: #{text} on job #{id}, instance_id = #{instance_id}, public_ip = #{public_ip}"

    
    e = Event.new(:text => text, :job_id => id, :instance_id => instance_id, :public_ip => public_ip)
    e.save
  end
  
  def utiltest
    lputs "in test"
  end
  
  def get_job_bucket_name(job)
    hostname = safe_bucket_name(`hostname`.chomp())
    "isb-cspotrun-job-bucket-#{hostname}-#{job.id}"
  end

  def create_job_bucket(job)
    create_bucket(get_job_bucket_name(job))
  end
  
  def s3login
    yaml = YAML::load_file("#{ENV['HOME']}/.s3conf/s3config.yml")
    key = yaml['aws_access_key_id']
    pass = yaml['aws_secret_access_key']
    return key,pass
  end
  
  def get_s3
    key,pass = s3login
    s3 = RightAws::S3.new(key,pass)
  end
  
  
  def create_bucket(name)
    cmd = "#{S3CMD_LOC}s3cmd mb s3://#{name}"
    stdout, stderr, error, status = run_cmd(cmd)
    lputs "stdout:\n#{stdout}"
    lputs "stderr:\n#{stderr}"
    lputs "status: #{status}"
  end
  
  def create_bucket_medium_old(name)
    get_s3.bucket(name, true)
  end
  
  def put_file(bucket, file, remotename=nil)
    rname = (remotename.nil?) ? file.split("/").last : remotename
    cmd = "#{S3CMD_LOC}s3cmd put #{file} s3://#{bucket}/#{rname}"
    stdout, stderr, error, status = run_cmd(cmd)
    lputs "stdout:\n#{stdout}"
    lputs "stderr:\n#{stderr}"
    lputs "status: #{status}"
  end
  
  def create_bucket_old(name)
    lputs "Creating bucket #{name}"
    cmd = "#{S3CMD_LOC}s3cmd.rb createbucket #{name}"
    stdout, stderr, error = run_cmd(cmd)
    if (error)
      lputs.info "stderr output creating bucket:\n#{stderr}"
    end
  end
  
  def move_data_to_job_bucket(job, job_bucket)
    put_file(get_job_bucket_name(job), "/tmp/initedEnv_#{job.id}.RData", "initedEnv.RData" )
  end
  
  def request_instances(job)
    if RAILS_ENV == 'production'
      request_instances_remote(job)
    else
      request_instances_local(job)
    end
  end
  
  
  def request_instances_local(job)
    cmd = job.command
    stdout, stderr, error = run_cmd(cmd)
    if (error)
      lputs "stderr output requesting instances:\n#{stderr}"
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
  
  def request_instances_remote(job)
    cmd = job.command
    querystring = '"'
    querystring += "pass=#{CSPOTRUN_PASS}&cmd=#{cmd.gsub(" ","+")}"
    querystring += '"'
    fullcmd = "curl -d  #{querystring} https://baliga.systemsbiology.net/cgi-bin/make-instance-request.rb"
    stdout, stderr, error = run_cmd(fullcmd)
    if (error)
      lputs "stderr output requesting instances:\n#{stderr}"
    end
    lputs "length of stdout: #{stdout.length}"
    lputs "result = \n#{stdout}"
    lines = stdout.split("\n")
    for line in lines
      ##SPOTINSTANCEREQUEST     sir-bac91c04    0.127   persistent      Linux/UNIX     open     2010-04-15T11:15:17-0800                                               ami-35c02e5c     m1.large        gsg-keypair     default
      segs = line.split(/\s/)
      i = Instance.new(:job_id => job.id, :sir_id => segs[1])
      i.save
      fire_event("creating instance #{i.sir_id}", job)
    end
    
  end
  
  def create_instance_buckets(job)
    for instance in job.instances
      name = "isb-cspotrun-instance-bucket-#{instance.sir_id}"
      create_bucket(name)
      fire_event("creating instance bucket #{name}", job)
    end
  end
  
  def safe_bucket_name(name)
    name.downcase.gsub("_","-")
  end
  
  def handle_job_completion(job, instance_id) #test with 70
    lputs "in Util.handle_job_completion, job id is #{job.id}"
    
    my_instance = Instance.find(instance_id)
    
    my_instance.status = "success"
    my_instance.save
    
    instances = job.instances
    
    success_stories = instances.select{|i|i.status == "success"}
    if (success_stories.length == instances.length)
      #Dir.mkdir("/tmp/cspotrun_output") unless (test(?d,"/tmp/cspotrun_output"))
      Dir.mkdir(STATIC_FILES_FOLDER) unless (test(?d, STATIC_FILES_FOLDER))
      jobdir = "#{STATIC_FILES_FOLDER}/job_#{job.id}"

      Dir.mkdir(jobdir) unless (test(?d, jobdir))

      instances.each_with_index do |instance, i|
        instance_dir = "#{jobdir}/instance_#{i+1}"
        Dir.mkdir(instance_dir) unless (test(?d, instance_dir))
        bucketname = "isb-cspotrun-instance-bucket-#{instance.sir_id}"
        get_file_from_s3(bucketname, "complete.image.RData", "#{instance_dir}/complete.image.RData")
        get_file_from_s3(bucketname, "cmonkey.log.txt.gz", "#{instance_dir}/cmonkey.log.txt.gz")
      end
      cmd = "cd #{STATIC_FILES_FOLDER};zip -r job_#{job.id}.zip job_#{job.id}/"
      zipfile = "#{STATIC_FILES_FOLDER}/job_#{job.id}.zip"
      stdout, stderr, error = run_cmd(cmd)
      if error
        lputs "stderr creating zip:\n#{stderr}"
      end
      lputs "stdout creating zip (#{cmd}) :\n#{stdout}"
      # todo - remove job dir if zip was created successfully
      unless (test(?s, zipfile).nil?)
        lputs "deleting directory..."
        `rm -rf #{STATIC_FILES_FOLDER}/job_#{job.id}`
      end
      url = "#{STATIC_FILES_URL}/job_#{job.id}.zip"
      Emailer.deliver_notify_success(url, job, File.stat(zipfile).size)
      
    end
    
    
    
  end
  
  
  def handle_job_failure(job, event)
    tail = nil
    unless (event.instance_id.nil?)
      my_instance = Instance.find(event.instance_id)
      my_instance.status = "failure"
      my_instance.save
      Dir.mkdir(STATIC_FILES_FOLDER) unless (test(?d, STATIC_FILES_FOLDER))
      jobdir = "#{STATIC_FILES_FOLDER}/job_#{job.id}"

      Dir.mkdir(jobdir) unless (test(?d, jobdir))
      instance_dir = "#{jobdir}/instance_#{my_instance.id}"
      Dir.mkdir(instance_dir) unless (test(?d, instance_dir))
      # todo - be a little more bulletproof here. there may not always be an instance bucket or log file in said bucket. 

      bucketname = "isb-cspotrun-instance-bucket-#{my_instance.sir_id}"
      get_file_from_s3(bucketname, "cmonkey.log.txt.gz", "#{instance_dir}/cmonkey.log.txt.gz")
      tail = `zcat #{instance_dir}/cmonkey.log.txt.gz|tail -200`
      `rm #{instance_dir}/cmonkey.log.txt.gz`
      `rmdir #{instance_dir}`
    end
    
    Emailer.deliver_notify_failure(job, event, tail)
    
    
  end
  
  
  def get_file_from_s3(bucketname, remotefile, localfile)
    cmd = "#{S3CMD_LOC}s3cmd get s3://#{bucketname}/#{remotefile} #{localfile}"
    stdout,stderr,error = run_cmd(cmd)
    if (error)
      lputs "stderr getting file from s3 (#{cmd}):\n#{stderr}"
    end
    lputs "stdout getting file from s3 (#{cmd}):\n#{stdout}"
  end
  
  def get_file_from_s3_old(bucketname, remotefile, localfile)
    cmd = "#{S3CMD_LOC}s3cmd.rb get #{bucketname}:#{remotefile} #{localfile}"
    stdout,stderr,error = run_cmd(cmd)
    if (error)
      lputs "stderr getting file from s3 (#{cmd}):\n#{stderr}"
    end
    lputs "stdout getting file from s3 (#{cmd}):\n#{stdout}"
  end
  
  
end