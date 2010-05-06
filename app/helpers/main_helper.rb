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
  
  
end
