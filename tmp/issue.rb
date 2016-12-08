
require 'rubygems'
require 'active_resource'

class Journal < ActiveResource::Base
  self.site='http://localhost:3000/'
end

class Issue < ActiveResource::Base
  include_root_in_json = true
  self.site='http://localhost:3000/'
  self.user='RuleD'
  self.password='18795650445ya'
  #self.primary_key ='49c74cac3ff28b4d905d130f6f53f58af030bb9f'
  has_many :journals
end

class Project < ActiveResource::Base
  self.site='http://localhost:3000/'
end



class JournalDetail < ActiveResource::Base
  self.site='http://localhost:3000/'
end

journals = Journal.all
puts journals
journalDetail = JournalDetail.all
puts journalDetail

issues=Issue.find(3)
issues.subject='change3'
puts issues.journals
if issues.save
  puts issues.id
else
  puts issues.errors.full_messages
end
puts issues.subject


projects = Project.find(1)
puts projects.id






'''
issue.subject="Reast"
issue.save

puts issue.subject
puts issue.updated_on
puts issue.author
puts issue.status.name
puts issue.description
puts issue.priority
'''
#jouranl = issue.journals


'''
projects = Project.find(1)
puts projects

journals = Journal.find(:all)
puts journals

detail = JournalDetail.find(:all)
puts detail'''