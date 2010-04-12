class MainController < ApplicationController
  
  require 'pp'
  
  include Util
  
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
    
    bucketname = "job_#{proj_id}"
    
    
    cmd = "ec2-request-spot-instances --price #{params[:price]} --instance-count #{params[:num_instances]} " +
      "--instance-type #{params[:processor_type]} --key #{AWS_KEY} --type persistent --user-data #{bucketname} #{AMI_ID}"
    puts cmd
    result = `#{cmd}`
    puts "result = #{result}"
  end
  
  
end
