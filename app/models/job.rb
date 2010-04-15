class Job < ActiveRecord::Base
  has_many :events
  has_many :instances
end
