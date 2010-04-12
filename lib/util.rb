module Util
  
  require 'rubygems'
  require 'right_aws'
  require 'open3'
  
  
  def start_sdb
    sdb = RightAws::SdbInterface.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
    newdomain = sdb.create_domain(dbname())
    puts "newdomain:"
    pp newdomain
    puts "domains:"
    domains = sdb.list_domains
    pp domains
    return sdb
  end
  
  def dbname
    "cspotrun_#{RAILS_ENV}"
  end
  
  def run_cmd(cmd)
    stdin, stdout, stderr = Open3.popen3(cmd)
    pretty_stderr = pretty_stream(stderr)
    pretty_stdout = pretty_stream(stdout)
    error = pretty_stderr.empty?
    return pretty_stdout,pretty_stderr,error
  end
  
  def pretty_stream(stream)
    arr = stream.readlines#.map{|i|i.chomp}
    arr.join()
  end
  
  def latest_price(instance_type)
    puts "getting latest price for #{instance_type}"
    timestamp = aws_timestamp(Time.now)
    cmd = "ec2-describe-spot-price-history --instance-type #{instance_type} --start-time #{timestamp}"
    stdout,stderr,error = run_cmd(cmd)
    if error
      puts "oops, an error:"
      puts stderr
    else
      puts "result:"
      puts stdout
      lines = stdout.split("\n")
      for line in lines
        next if line.downcase =~ /windows/
        segs = line.split(/\s/)
        return segs[1].to_f
      end
      
    end
  end
  
  def recommended_price(current_price)
    current_price + 0.01
  end
  
  def aws_timestamp(timevar)
    utc = timevar.utc
     "#{utc.year}-#{"%02d" % utc.mon}-#{"%02d" % utc.mday}T#{"%02d" % utc.hour}:#{"%02d" % utc.min}:#{"%02d" % utc.sec}.000Z"
  end
  
end