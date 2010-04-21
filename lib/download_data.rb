class DownloadData
  jobs = Job.find :all, :conditions => 'id > 65'
  
  i = 1
  
  outdir = "/Users/dtenenbaum/cspotrun_output/10_egrin_runs"
  
  for job in jobs
    for instance in job.instances
      bucket_name = "cspotrun-instance-bucket-#{instance.sir_id}"
      dirname = "#{outdir}/run-#{i}"
      Dir.mkdir(dirname)
      i += 1
      cmd = "s3cmd.rb get #{bucket_name}:complete.image.RData #{dirname}/complete.image.RData"
      puts cmd
      `#{cmd}`
    end
  end
end