#!/usr/bin/ruby
require 'ovfparse'

uri = "file:///Users/ideshmukh/workspace/cops/ovfparse/test_files"
vmRepo = VmRepository.create(uri)
puts "\n\n****************************\n"
puts "protocol: " + vmRepo.protocol + "\n"
puts "url: " + vmRepo.url + "\n"
puts "uri: " + vmRepo.uri + "\n"
packages = vmRepo.fetch
puts "packages: " + packages.to_s + "\n"
pkg = packages[1]
puts "selected package: " + pkg.to_s + "\n"
pkg.fetch 
puts pkg.xml 
puts "\n\n****************************\n"

# uri = "http://localhost/repo/"
# vmRepo = VmRepository.create(uri)
# puts "\n\n****************************\n"
# puts "protocol: " + vmRepo.protocol + "\n"
# puts "url: " + vmRepo.url + "\n"
# puts "uri: " + vmRepo.uri + "\n"
# packages = vmRepo.fetch
# ovfTest = packages[1]
# ovfTest.fetch 
# puts ovfTest.xml
# 
# repo = VmRepository.create(nil)
# puts repo.inspect 
# 
#             repo = VmRepository.create("http://cops-af-lib.mitre.org/") #shouldn't it uri and not url?
#             repo = VmRepository.create("http://ambrosia.mitre.org/repo/") #shouldn't it uri and not url?
# 
#             ovfs = repo.fetch
#             ovfs.each { |ovf|
#               ovf.fetch
#               products = ovf.ProductSection #equivalent to: (ovf.xml/'ProductSection')
#             }
# 
# package = VmPackage.create("file://ambrosia/public/vmlib/someOVF.ovf")
# package = VmPackage.create("http://cops-af-lib.mitre.org//Base OS Package (jeos)-Ubuntu-20090917.ovf")
# package.fetch 
# puts package.xml
# puts package.ProductSection
# 
# uri = "https://localhost/repo/"
# vmRepo = VmRepository.create(uri)
# puts "\n\n****************************\n"
# puts "protocol: " + vmRepo.protocol + "\n"
# puts "url: " + vmRepo.url + "\n"
# puts "uri: " + vmRepo.uri + "\n"
# packages = vmRepo.fetch
# ovfTest = packages[1]
# ovfTest.fetch 
# puts ovfTest.xml
# 
# uri = "ftp://localhost/repo"
# vmRepo = VmRepository.create(uri)
# puts "\n\n****************************\n"
# puts "protocol: " + vmRepo.protocol + "\n"
# puts "url: " + vmRepo.url + "\n"
# puts "uri: " + vmRepo.uri + "\n"
# packages = vmRepo.fetch
# ovfTest = packages[1]
# ovfTest.fetch 


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

