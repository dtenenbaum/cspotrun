class ConsumeMessages
  # warning! this will consume all messages!
  
  require 'pp'
  require 'rubygems'
  require 'yaml'

  require 'right_aws'
  
  hostname = `hostname`.chomp()
  
  include Util

  def self.start_queue()
    sqs = RightAws::SqsGen2.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
    queue1 = sqs.queue("cspotrun-from-instances")
    return sqs, queue1
  end

  
  sqs, queue1 = start_queue()



  start_queue()
  
  while (true)
    message = queue1.receive
    if message.nil?
      puts "no messages!"
      exit
    else
      message.delete
      puts "deleted message"
    end
    
    sleep 1
    
  end
  
end