class Event < ActiveRecord::Base
  belongs_to :job
  cattr_reader :per_page
  @@per_page = 15
end
