class Atest
  require 'rubygems'
  require 'right_aws'
  
  require "#{RAILS_ROOT}/lib/util.rb"
  include Util
  
  require 'pp'
  
  s3 = RightAws::S3.new(AWS_ACCOUNT_KEY, AWS_SECRET_KEY)
  
  bucket = s3.bucket("cani")
  
  puts bucket.keys.size
  
  #pp bucket.keys
  
  for key in bucket.keys
    puts key
  end
  
  
end