class MainController < ApplicationController
  
  require 'pp'
  
  require 'yaml'
  
  include Util

  def nothing
    render :text => "ok"
  end
  
  def index
    @small_price = latest_price("m1.large")
    @large_price = latest_price("c1.xlarge")
    @small_recommended = recommended_price(@small_price)
    @large_recommended = recommended_price(@large_price)
  end
  
  def test
    render :text => "ok"
  end
  
  def submit_job
    @blanks = params.values.find_all{|i|i.empty?}
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
    @job.email = params['email']

    #begin
    #  Job.transaction do

        @job.save
        @job.user_data_file = "/tmp/user_data_#{@job.id}.txt"

        @job.command = "ec2-request-spot-instances --price #{params[:price]} --instance-count #{params[:num_instances]} " +
          "--instance-type #{params[:processor_type]} --key #{AWS_KEY} --type persistent --user-data-file #{@job.user_data_file} #{AMI_ID}"


        @job.ratios_file = "/tmp/ratios_#{@job.id}.txt"

        File.open(@job.ratios_file, "w")  {|file|file.puts(params['ratios'])}

        @job.save


        spawn_job(@job)

    #  end
    #rescue Exception => ex
    #  puts ex.message
    #  puts ex.backtrace
    #end
    
    
  end
  
  
end
