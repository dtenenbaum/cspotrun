class Pricer
  
  include Util
  
  def get_price_data(instance_type="c1.xlarge")
    cmd = "ec2-describe-spot-price-history --instance-type #{instance_type} --start-time 2008-05-04T13:53:45-0800 -d Linux/UNIX"
    stdout,stderr,error,status = run_cmd(cmd)
    #puts "stderr = #{stderr}, status = #{status}, stdout = \n#{stdout}"
    @ary = []
    for line in stdout.split("\n")
      h = {}
      segs = line.split("\t")
      h[:price] = segs[1].to_f
      h[:time] = Time.parse(segs[2])
      @ary.push h
    end
    @ary
  end
  
  def set_price_data=(ary)
    @ary = ary
  end

  def latest_price()
    @ary.last[:price]
  end
  
  def latest_plus_one_cent()
    latest_price + 0.01
  end
  
  def max()
    max = 0
    for item in @ary
      max = item[:price] if item[:price] > max
    end
    max
  end
  
  def min()
    min = 1000
    for item in @ary
      min = item[:price] if item[:price] < min
    end
    min
  end
  
  def latest_time
    @ary.last[:time]
  end
  
  def oldest_time
    @ary.first[:time]
  end
  
  def timespan # in days
    (latest_time - oldest_time)/(60*60*24)
  end
  
end