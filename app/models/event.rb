class Event < ActiveRecord::Base
  belongs_to :job
  belongs_to :instance
  
  cattr_reader :per_page
  @@per_page = 15
  
  include Util
  
  
  after_save :handle_after_save
  
  def handle_after_save
    puts "in handle_after_save, text = #{text}"
    if (text == "cmonkey processing complete")
      # assemble output data into zip file, notify user that run is complete
      handle_job_completion(job, instance_id)
    elsif (text.downcase =~ /^error/)
      handle_job_failure(job, self)
    end
  end
  
end
