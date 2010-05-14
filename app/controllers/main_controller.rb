class MainController < ApplicationController
  
  require 'pp'
  
  require 'yaml'
  
  require 'rubygems'
  require 'will_paginate'
  
  require 'systemu'

  filter_parameter_logging :password

  
  
  include Util



  Time.zone = "Pacific Time (US & Canada)"

  before_filter :authorize, :except => [:login, :logout]

#  def upltest
#  end

  def authorize
    if (session[:user].nil? or session[:user].empty?)
      redirect_to :action => "login" and return false
    end
  end

  def login
    lputs "in login, rm= #{request.method}"
    if (request.method == :post)
      lputs "method == post"
      user = User.authenticate(params[:email], params[:password], false)
      if user == false
        lputs "invalid login"
        flash[:notice] = "Invalid Login"
        redirect_to :action => "login" and return false
      else
        lputs "valid login"
        user.updated_at = Time.now
        user.save
        session[:user] = params['email']
        redirect_to :action => "welcome" and return false
      end
    end
  end
  
  def logout
    session[:user] = nil
    redirect_to :action => "login"
  end


  def upl
    f = params['uploaded_file']
    headers['Content-type'] = 'text/plain'
    s  = ""
    while (line = f.gets)
      s += line
    end
    render :text =>  s
  end

  def nothing
    utiltest
    render :text => "ok"
  end
  
  def new_job
    @large_price, @small_price  = latest_price()
    #@small_price = latest_price("m1.large")
    #@large_price = latest_price("c1.xlarge")
    @small_recommended = recommended_price(@small_price)
    @large_recommended = recommended_price(@large_price)
  end
  
  def test_method # do not call a method "test", it conflicts with Kernel.test
    render :text => "ok"
  end
  
  def index
    render :action => "welcome" and return false
  end
  
  
  def my_jobs
    lputs("current user is: #{session[:user]}")
    @all = false
    @jobs = Job.paginate_by_email session[:user], :page => params[:page], :order => 'created_at DESC'
    render :action => "jobs"
  end
  
  def all_jobs
    @all = true
    @jobs = Job.paginate :page => params[:page], :order => 'created_at DESC'
    render :action => "jobs"
  end
  
  def show_log_file
    headers['Content-type'] = 'text/plain'
    instance = Instance.find params[:id]
    file = get_log_file(instance)
    #send_file file, :disposition => :inline
    render :file => file
  end
  
  
  def events
    #puts "timezone = #{Time.zone}"
    @job = Job.find params['job_id']
    @status = get_job_status(@job)
    @log_info = []
    for instance in @job.instances
      @log_info << [instance.id, has_log_file?(instance)]
    end
    
    pp @status
    @public_ip = nil
#    if (@status.has_key?(:cspotrun_instance_id))
#      @public_ip = Instance.find(@status[:cspotrun_instance_id]).public_ip
#    end
    @events = Event.paginate_by_job_id params['job_id'], :include => :instance, :page => params[:page], :order => 'created_at DESC'
    @zip_file_size, @zip_file_url = zip_file_size_and_url(@job)
    @is_job_complete = is_job_complete?(@job)
  end
  
  def submit_job
    #@blanks = []
    #for item in params.values
    #  @blanks << item if (item.respond_to?(:empty?) and item.empty?)
    #end
    
    #render :action => "fillinfields" and return false unless @blanks.empty?
    
    @job = Job.new()
    
    @job.user_supplied_rdata = (params[:preinitialized_rdata_file].respond_to?(:path)) ? true : false
    
    #render :text => params[:preinitialized_rdata_file].path and return false if true
    #render :text => @job.user_supplied_rdata and return false if true
    
    @job.name = params['job_name']
    @job.price = params['price']
    @job.instance_type = params['processor_type']
    @job.num_instances = params['num_instances']
    @job.k_clust = params['k']
    @job.status = 'starting'
    @job.organism = params['organism']
    @job.project = params['project']
    @job.is_test_run = (params['is_test_run'] == 'true') ? true : false
    @job.email = session[:user]
    @job.n_iter = params['n_iter']

    #begin
    #  Job.transaction do

        @job.save
        
        fire_event("starting job #{@job.name} (id #{@job.id})", @job)
        @job.user_data_file = "/tmp/user_data_#{@job.id}.txt"

        @job.command = "#{EC2_TOOLS_HOME}ec2-request-spot-instances --price #{params[:price]} --instance-count #{params[:num_instances]} " +
          "--instance-type #{params[:processor_type]} --key #{AWS_KEY} --type persistent --user-data-file #{@job.user_data_file} #{AMI_ID}"

          

       if (@job.user_supplied_rdata)
         fileobj = params[:preinitialized_rdata_file]
         FileUtils.mv fileobj.path, "/tmp/initedEnv_#{@job.id}.RData"
         
         
         #File.open("/tmp/initedEnv_#{@job.id}.RData", "wb") { |f| f.write(fileobj.read) }


       else
         @job.ratios_file = "/tmp/ratios_#{@job.id}.txt" 

         fileobj = params[:uploaded_file]

         lputs "writing to #{@job.ratios_file}..."

         FileUtils.mv fileobj.path, @job.ratios_file

         #File.open(@job.ratios_file, "wb") { |f| f.write(fileobj.read) }


         #File.open(@job.ratios_file, "w")  do |file|
           # todo change this to binary write because line endings may vary on different OS's
           #while (line = fileobj.gets)
          #   file.puts line
          # end
         #end
         
       end

        

        @job.save

        puts "ENV['RAILS_ENV'] = #{ENV['RAILS_ENV']}"

        # todo - put this log in shared area on production
        if (RAILS_ENV == 'production')
          cmd = "rm -f #{LOG_LOC}/spawn.log && cd #{RAILS_ROOT} &&  #{RUBY_LOC} ./script/runner SpawnJob #{@job.id} > #{LOG_LOC}/spawn.log 2>&1 &"
        else
          cmd = "rm -f #{RAILS_ROOT}/log/spawn.log && cd #{RAILS_ROOT} && ./script/runner SpawnJob #{@job.id} > #{RAILS_ROOT}/log/spawn.log 2>&1 &"
        end
        lputs "spawn command = \n#{cmd}"
        stdout, stderr, error  = run_cmd(cmd)
        if  (error)
          lputs "stderr output:\n#{stderr}"
        end
        lputs "stdout output:\n#{stdout}"

       ## spawn_job(@job)

    #  end
    #rescue Exception => ex
    #  puts ex.message
    #  puts ex.backtrace
    #end
    @events = Event.paginate_by_job_id @job.id, :page => params[:page], :order => 'created_at DESC'
    
    flash[:notice] = "Your job has been submitted with ID #{@job.id}. You will receive email when your job completes or fails."
    render(:action => "events", :job_id => @job.id) and return false
  end
  
  def kill
    job = Job.find(params[:job_id])
    type = ""
    if params[:id] =~ /^sir-/
      type = "request"
      kill_requests(params[:id])
      fire_event("instance request #{params[:id]}  killed by user", job)
    elsif params[:id] =~ /^i-/
      type = "instance"
      kill_instances(params[:id])
      fire_event("instance #{params[:id]} killed by user", job, params[:id])
    end
    flash[:notice] = "#{type} #{params[:id]} killed."
    redirect_to :action => "events", :job_id => params[:job_id]
  end
  
  def kill_all_requests
    flash[:notice] = "Requests killed."
    job = Job.find params[:job_id]
    
    kill_requests(*job.instances.map{|i|i.sir_id})
    redirect_to :action => "events", :job_id => params[:job_id]
  end
  
  def kill_all_instances
    flash[:notice] = "Instances killed. They will be restarted if there are still active requests."
    instances = params[:instance_ids].split(",")
    kill_instances(instances)
    redirect_to :action => "events", :job_id => params[:job_id]
  end
  
  def kill_all
    flash[:notice] = "All requests and instances killed."
    job = Job.find params[:job_id]
    instances = params[:instance_ids].split(",")
    kill_requests(*job.instances.map{|i|i.sir_id})
    kill_instances(*instances)
    redirect_to :action => "events", :job_id => params[:job_id]
  end
  
  def email_link
    job = Job.find params[:job_id]
    handle_job_completion(job, job.instances.first.id)
    flash[:notice] = "We are downloading the data and will send you an email when we're done."
    redirect_to :action => "events", :job_id => params[:job_id]
  end
  

  def hose
    bortz()
    render :text => "ok"
  end
  
end
