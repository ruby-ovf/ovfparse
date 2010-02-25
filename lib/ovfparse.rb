require 'rubygems'
require 'nokogiri'
require 'net/ftp'
require 'net/http'
require 'net/https'
require 'pathname'

dir = Pathname(__FILE__).dirname.expand_path

require dir + 'ovfparse/vmrepository'
require dir + 'ovfparse/vmpackage'

