#!/usr/bin/ruby
require 'ovfparse'

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
#packages = vmRepo.fetch
#ovfTest = packages[1]
#ovfTest.get 
#puts ovfTest.xml

#package = VmPackage.create("file://ambrosia/public/vmlib/someOVF.ovf")
package = VmPackage.create("http://ambrosia/repo/someOVF.ovf")
package.get 
#puts package.xml
puts package.ProductSection

#uri = "https://localhost/repo/"
#vmRepo = VmRepository.create(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#packages = vmRepo.fetch
#ovfTest = packages[1]
#ovfTest.get 
#puts ovfTest.xml

#uri = "ftp://localhost/repo"
#vmRepo = VmRepository.create(uri)
#puts "\n\n****************************\n"
#puts "protocol: " + vmRepo.protocol + "\n"
#puts "url: " + vmRepo.url + "\n"
#puts "uri: " + vmRepo.uri + "\n"
#packages = vmRepo.fetch
#ovfTest = packages[1]
#ovfTest.get 


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

