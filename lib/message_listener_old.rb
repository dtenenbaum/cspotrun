class MessageListener


  require 'pp'
  require 'rubygems'

  require 'right_aws'

  #todo get this info from a secret place, don't hardcode it
  sqs = RightAws::SqsGen2.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
  queue1 = sqs.queue("cspotrun-from-instances")
  
  message = queue1.receive
  puts message.to_s
  message.delete unless message.nil?
  
end