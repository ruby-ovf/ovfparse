#!/usr/bin/ruby
require 'vmrepository'


uri = "http://test.com/test"
vmRepo = VmRepository.new(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts "repo: " + vmRepo.repo.inspect + "\n"

uri = "https://test.com/test"
vmRepo = VmRepository.new(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts "repo: " + vmRepo.repo.inspect + "\n"

uri = "ftp://test.com/test"
vmRepo = VmRepository.new(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts "repo: " + vmRepo.repo.inspect + "\n"

uri = "esx4://test.com/test"
vmRepo = VmRepository.new(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts "repo: " + vmRepo.repo.inspect + "\n"

uri = "vc4://test.com/test"
vmRepo = VmRepository.new(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
puts "repo: " + vmRepo.repo.inspect + "\n"

#uri = "esx://test.com/test"
#vmRepo = VmRepository.new(uri)

#uri = "vc://test.com/test"
#vmRepo = VmRepository.new(uri)


uri = "unknown://test.com/test"
vmRepo = VmRepository.new(uri)

