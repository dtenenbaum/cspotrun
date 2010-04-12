module Util
  
  require 'rubygems'
  require 'right_aws'
  
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
end