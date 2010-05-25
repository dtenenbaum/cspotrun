module MainHelper
  
  def  describe_state(state, type=nil, id=nil, job=nil)
    img = ""
    link = ""
    
    kill = link_to "Kill",  {:action => "kill", :type => type, :id => id, :job_id => job.id},
      {:class => "killrequest", :confirm => "Are you sure?"}
    
    if state == "pending"
      img = image_tag("instance-starting.gif")
      link = kill
    elsif state == "running" or state == "active" or state == "open"
      img = image_tag("instance-running.gif")
      link = kill
    elsif state == "shutting-down"
      img = image_tag("instance-shutting-down.gif")
    elsif state == "terminated" or state == "cancelled"
      img = image_tag("instance-terminated.gif")
    end
    "#{img} #{state} #{link}"
  end


  def job_status(job)
    img = ""
    if job.status == "running" 
      img = image_tag("instance-running.gif", :alt => "job is running")
    elsif job.status == "success"
      img = image_tag("checkmark.png", :alt => "job has completed successfully")
    elsif job.status = "starting"
      img = image_tag("instance-starting.gif", :alt => "starting")
    elsif job.status == "failure"
      img = image_tag("error.png", :alt => "one or more instances of this job has failed")
    end
    img
#    "#{img} #{job.status}"
  end
  
  def instance(item)
    puts "hohum"
    if item.has_key?(:cspotrun_instance_id)
       return Instance.find(item[:cspotrun_instance_id])
    end
    nil
  end
  
  def instance_id(item)
    i = instance(item)
    return i.id unless i.nil?
    ""
  end
    
  
  def log_info(item)
    i = instance(item)
    return false if i.nil?
    for item in @log_info
      return item.last if item.first == i.id
    end
    false
  end
  
  def instance_ids
    res = []
    for item in @status
      res.push item[:instance_id] if item.has_key?(:instance_id)
    end
#    return nil if res.empty?
    return res.join(",")
  end

  
  
end
