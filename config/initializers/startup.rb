class Startup
  
  require 'pp'
  require 'rubygems'

  require 'right_aws'
  
  sqs = RightAws::SqsGen2.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
  queue1 = sqs.queue("cspotrun-from-instances")
  
  #logger.info("startup class, main thread")
  puts("startup class, in main thread")
  thread = Thread.new() do
    puts("inside a thread")
    while (true)
      #puts "in timer loop"
      message = queue1.receive
      unless message.nil?
        puts message.to_s
        message.delete
      end
      
      sleep(1)
    end
  end
  
  
end