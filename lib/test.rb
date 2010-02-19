#!/usr/bin/ruby
require 'vmrepository'

#uri = "file://../test_files"
#vmRepo = VmRepository.create(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#puts vmRepo.fetch

#uri = "http://localhost/repo/"
#vmRepo = VmRepository.create(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#puts vmRepo.fetch

#uri = "https://localhost/repo/"
#vmRepo = VmRepository.create(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#puts vmRepo.fetch
#
uri = "ftp://localhost/repo"
vmRepo = VmRepository.create(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts vmRepo.fetch
#
#uri = "esx4://test.com/test"
#vmRepo = VmRepository.new(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#
#uri = "vc4://test.com/test"
#vmRepo = VmRepository.new(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#
#


#########################################
# THESE SHOULD THROW EXCEPTIONS
# #######################################
#uri = "esx://test.com/test"
#vmRepo = VmRepository.new(uri)

#uri = "vc://test.com/test"
#vmRepo = VmRepository.new(uri)

#uri = "unknown://test.com/test"
#vmRepo = VmRepository.new(uri)

