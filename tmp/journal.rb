require 'rubygems'
require 'active_resource'
class Journal < ActiveResource::Base
  self.site='http://localhost:3000/'

end



journals = Journal.find(1)

puts journals