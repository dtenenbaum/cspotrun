class Startup
  
  require 'pp'
  require 'rubygems'

  require 'right_aws'
  

  def self.start_queue()
    sqs = RightAws::SqsGen2.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
    queue1 = sqs.queue("cspotrun-from-instances")
    return sqs, queue1
  end

  
  
  sqs, queue1 = start_queue()



  start_queue()

  # todo - deal with the issue of consuming messages - if there are two or more instances of this webapp running
  # (development and production), they will not see the messages you expect them to see because currently each message
  # is consumed once and then deleted. Perhaps a better approach is to mark a message as read but don't delete it.
  # so the flow would be: 
  #   get a message
  #   get some kind of unique id from the message
  #   see if we already have a message with that id from our database
  #   if not, put the message in the database, respond to it, mark it as viewed
  #   if we've already seen the message, ignore it
  # that could result in lots of wading through already-seen messages. If you had some periodic cron job that
  # pruned messages that have already been dealt with, you could solve that, but that periodic cron job
  # would need to know about all the instances of the webapp that are listening to messages. So rethink this.
  
  #logger.info("startup class, main thread")
  puts("startup class, in main thread")
  thread = Thread.new() do
    puts("inside a thread")
    while (true)
      #puts "in timer loop"
      begin
        # http://rightscale.rubyforge.org/right_aws_gem_doc/classes/RightAws/Sqs/Message.html
        message = queue1.receive
        unless message.nil?
          #puts message.methods.sort
          puts "message id = #{message.id}"
          puts "sent at = #{message.sent_at}"
          puts "received at = #{message.received_at}"
          puts "message body:"
          puts message.body
          message.delete
        end
      rescue Exception => ex
        puts "exception, trying to restart queue"
        puts ex.message
        sqs, queue1 = start_queue()
      end
      
      
      
      sleep(1)
    end
  end
  
  
  
end