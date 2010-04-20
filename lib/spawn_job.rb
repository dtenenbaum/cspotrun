class SpawnJob
  unless ARGV.size == 1
    puts "supply a job id"
    exit
  end
  
  
  include Util
  
end


job = Job.find ARGV.first



logger = RAILS_DEFAULT_LOGGER


sj = SpawnJob.new
sj.spawn_job(job)
