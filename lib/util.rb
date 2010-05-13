module Util
  
  require 'rubygems'
  require 'right_aws'
  require 'open3'
  require 'systemu'
  require 'yaml'
  require 'pp'
  
  
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
    result = ec2.describe_spot_price_history(:start_time => Time.now, :instance_types => ["c1.xlarge","m1.large"], :product_description => "Linux/UNIX")
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
  
  
  
  def recommended_price(current_price)
    current_price + 0.01
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
  
  def zip_file_size_and_url(job)
    if (size = Kernel.test(?s, "#{STATIC_FILES_FOLDER}/job_#{job.id}.zip"))
      if size > 4096
        return "#{(size/1_000_000).to_i} MB", "#{STATIC_FILES_URL}/job_#{job.id}.zip"
      end
    end
    return nil,nil
  end

  def fire_event(text, job, instance_name=nil, public_ip=nil)
    id  = (job.is_a?(Fixnum)) ? job : job.id
    
    instance_id = nil

    unless (instance_name.nil?)
      instance = Instance.find_by_sir_id(instance_name)
      unless instance.nil?
        instance_id = instance.id
        unless (public_ip.nil?)
          instance.public_ip = public_ip
          instance.save
        end
      end
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
  
  
  def get_job_status(job)
    instances = job.instances
    return nil if instances.nil? or instances.empty?
    unfiltered_instance_request_results = ec2.describe_spot_instance_requests
    #lputs "raw sir results:"
    #pp unfiltered_instance_request_results
    instance_request_results = []
    list_of_instances = []
    for item in unfiltered_instance_request_results
      #lputs "sir id  = #{item[:spot_instance_request_id]}"
      if instances.detect{|i|i.sir_id == item[:spot_instance_request_id]}
        instance_request_results.push item
        if item.has_key?(:instance_id)
          list_of_instances.push item[:instance_id]
        end
      end
    end
    
    
    instance_results = ec2.describe_instances(list_of_instances)
    
    #lputs "sir results:"
    #pp instance_request_results
    #lputs "instance results:"
    #pp instance_results
    #lputs "list of instances:"
    #pp list_of_instances
    new_list = []

    for item in instance_request_results
      if (item.has_key?(:instance_id) and (f = instance_results.detect{|i|i[:aws_instance_id] == item[:instance_id]}))
        #lputs "we are here!"
        cspotrun_instance = instances.detect{|i|i.sir_id == item[:instance_id]}
        item[:cspotrun_instance_id] = cspotrun_instance.id unless cspotrun_instance.nil?
        item[:instance_info] = f
      end
      new_list << item
    end
    
#    lputs "sir results:"
#    pp new_list
    return (new_list.empty?) ? nil : new_list
  end
  
  def put_file(bucket, file, remotename=nil)
    rname = (remotename.nil?) ? file.split("/").last : remotename
    cmd = "#{S3CMD_LOC}s3cmd put #{file} s3://#{bucket}/#{rname}"
    stdout, stderr, error, status = run_cmd(cmd)
    lputs "stdout:\n#{stdout}"
    lputs "stderr:\n#{stderr}"
    lputs "status: #{status}"
  end
  
  def move_data_to_job_bucket(job, job_bucket)
    put_file(get_job_bucket_name(job), "/tmp/initedEnv_#{job.id}.RData", "initedEnv.RData" )
  end
  
  def request_instances(job)
    user_data_yaml = YAML.load_file job.user_data_file
    user_data = YAML::dump(user_data_yaml)
    
    lputs "user data = "
    pp user_data
    args = {:image_id => AMI_ID, :spot_price => job.price, :instance_type => job.instance_type, :instance_count => job.num_instances,
      :key_name => AWS_KEY, :type => "persistent", :user_data => user_data}
    lputs "args = "
    pp args
    results = ec2.request_spot_instances args
    pp results
    for result in results
      i = Instance.new(:job_id => job.id, :sir_id => result[:spot_instance_request_id])
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

  def is_job_complete?(job)
    instances = job.instances
    return false if instances.empty?
    success_stories = instances.select{|i|i.status == "success"}
    return (success_stories.length == instances.length)
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
    lputs "nothing to do"
    
    
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
  
  def kill_requests(*ids)
    ec2.cancel_spot_instance_requests(ids)
  end
  
  def kill_instances(*ids)
    ec2.terminate_instances(ids)
  end
  
  def ec2()
    RightAws::Ec2.new(AWS_ACCOUNT_KEY, AWS_SECRET_KEY)
  end
  
  
end