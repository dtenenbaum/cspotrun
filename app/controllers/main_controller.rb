class MainController < ApplicationController
  
  require 'pp'
  
  require 'yaml'
  
  require 'rubygems'
  require 'will_paginate'
  
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
    puts "in login, rm= #{request.method}"
    if (request.method == :post)
      puts "method == post"
      user = User.authenticate(params[:email], params[:password], false)
      if user == false
        puts "invalid login"
        flash[:notice] = "Invalid Login"
        redirect_to :action => "login" and return false
      else
        puts "valid login"
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
    @small_price = latest_price("m1.large")
    @large_price = latest_price("c1.xlarge")
    @small_recommended = recommended_price(@small_price)
    @large_recommended = recommended_price(@large_price)
  end
  
  def test
    render :text => "ok"
  end
  
  def index
    render :action => "welcome" and return false
  end
  
  
  def my_jobs
    @jobs = Job.paginate_by_email session[:user], :page => params[:page], :order => 'created_at DESC'
    render :action => "jobs"
  end
  
  def all_jobs
    @jobs = Job.paginate :page => params[:page], :order => 'created_at DESC'
    render :action => "jobs"
  end
  
  
  def events
    #puts "timezone = #{Time.zone}"
    
    @events = Event.paginate_by_job_id params['job_id'], :page => params[:page], :order => 'created_at DESC'
  end
  
  def submit_job
    @blanks = []
    for item in params.values
      @blanks << item if (item.respond_to?(:empty?) and item.empty?)
    end
    
#    @blanks = params.values.find_all{|i|i.empty?}
    render :action => "fillinfields" and return false unless @blanks.empty?
    # do some validation
    # generate a project id
    
    @job = Job.new()
    
    
    @job.name = params['job_name']
    @job.price = params['price']
    @job.instance_type = params['processor_type']
    @job.num_instances = params['num_instances']
    @job.k_clust = params['k']
    @job.status = 'starting'
    @job.organism = params['organism']
    @job.project = params['project']
    @job.is_test_run = (params['is_test_run'] == 'true') ? true : false
    @job.email = session['user']
    @job.n_iter = params['n_iter']

    #begin
    #  Job.transaction do

        @job.save
        
        fire_event("starting job #{@job.name} (id #{@job.id})", @job)
        @job.user_data_file = "/tmp/user_data_#{@job.id}.txt"

        @job.command = "ec2-request-spot-instances --price #{params[:price]} --instance-count #{params[:num_instances]} " +
          "--instance-type #{params[:processor_type]} --key #{AWS_KEY} --type persistent --user-data-file #{@job.user_data_file} #{AMI_ID}"

          

        @job.ratios_file = "/tmp/ratios_#{@job.id}.txt"
        
        fileobj = params['uploaded_file']

        puts "writing to #{@job.ratios_file}..."

        File.open(@job.ratios_file, "w")  do |file|
          while (line = fileobj.gets)
            file.puts line
          end
        end
        

        @job.save


        cmd = "rm -f #{RAILS_ROOT}/log/spawn.log && cd #{RAILS_ROOT} && ./script/runner SpawnJob #{@job.id} > #{RAILS_ROOT}/log/spawn.log 2>&1 &"
        puts "spawn command = \n#{cmd}"
        stdout, stderr, error  = run_cmd(cmd)
        if  (error)
          puts "stderr output:\n#{stderr}"
        end
        puts "stdout output:\n#{stdout}"

       ## spawn_job(@job)

    #  end
    #rescue Exception => ex
    #  puts ex.message
    #  puts ex.backtrace
    #end
    @events = Event.paginate_by_job_id @job.id, :page => params[:page], :order => 'created_at DESC'
    
    flash['notice'] = "Your job has been submitted with ID #{@job.id}"
    render(:action => "events", :job_id => @job.id) and return false
  end
  
  
end
