# start this up separately from the rails app
class MessageListener
  
  puts "running MessageListener..."
  
  require 'pp'
  require 'rubygems'
  require 'yaml'

  require 'right_aws'
  
  
  include Util

  def start_queue()
    sqs = RightAws::SqsGen2.new(AWS_ACCOUNT_KEY,AWS_SECRET_KEY)
    queue1 = sqs.queue("cspotrun-from-instances", true)
    return sqs, queue1
  end




#  start_queue()

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
  
  #  update - that has been dealt with by putting the name of the originating host in the message and ignoring messages not so marked.
  
  #logger.info("startup class, main thread")
  
  
def lputs(msg)
  logger = RAILS_DEFAULT_LOGGER
  logger.info msg
  puts msg
end
  
def start
  lputs("startup class, in main thread")
  hostname = `hostname`.chomp()
  sqs, queue1 = start_queue()
  
  

    while (true)
      #puts "in timer loop"
      begin
        # http://rightscale.rubyforge.org/right_aws_gem_doc/classes/RightAws/Sqs/Message.html
        #puts "waiting"
        message = queue1.receive
        unless message.nil?
          
          bodyhash = YAML::load message.body
          
          
          puts "originating host = #{bodyhash['user_data_originating_host']}"
          
          if (bodyhash['user_data_originating_host'] == hostname)

            lputs "message id = #{message.id}"
            lputs "sent at = #{message.sent_at}"
            lputs "received at = #{message.received_at}"
            lputs "message body:"


            lputs message.body

            lputs "bodyhash:"

            pp bodyhash 
            job_id = bodyhash['user_data_job_id']
            public_ip = bodyhash['public-hostname']
            # todo - don't delete message unless fire_event is successful
            fire_event(bodyhash['message'], job_id, bodyhash['spot-instance-request-id'], public_ip)

            
            
            lputs "deleting message"
            message.delete 
          else
            puts "got a message for someone else"
          end
          
        end
      rescue Exception => ex
        lputs "exception, trying to restart queue"
        lputs ex.message
        sqs, queue1 = start_queue()
      end
      
      
      
      sleep(1)
    end
  
end  
  
end

logger = RAILS_DEFAULT_LOGGER
ml = MessageListener.new
ml.start