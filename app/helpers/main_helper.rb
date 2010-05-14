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
  
  
  def instance(item)
    if item.has_key?(:cspotrun_instance_id)
       return Instance.find(item[:cspotrun_instance_id])
    end
    nil
  end
  
  def instance_id(item)
    instance = instance(item)
    return instance.id unless instance.nil?
    ""
  end
    
  
  def log_info(item)
    instance = instance(item)
    for item in @log_info
      return item.last if item.first == instance.id
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
