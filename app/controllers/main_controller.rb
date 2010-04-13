class MainController < ApplicationController
  
  require 'pp'
  
  include Util
  
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
    proj_id = Time.now.to_i.to_s
    params['project_id'] = proj_id
    sdb = start_sdb()
    sdb.put_attributes(dbname, "jobs", params)
    
    bucketname = ""
    if (params[:just_for_fun] == 'true')
      bucketname += "just_for_fun_"
    end
    
    bucketname += "job_#{proj_id}"
    
    
    cmd = "ec2-request-spot-instances --price #{params[:price]} --instance-count #{params[:num_instances]} " +
      "--instance-type #{params[:processor_type]} --key #{AWS_KEY} --type persistent --user-data #{bucketname} #{AMI_ID}"
    puts "command = "
    puts cmd
    
    stdout, stderr, error = run_cmd(cmd)
    puts "was there an error? #{error}"
    puts "result = "
    # save the result. there will be one line per instance requested, each with a different SIR id
    puts (error) ? stderr : stdout
  end
  
  
end
