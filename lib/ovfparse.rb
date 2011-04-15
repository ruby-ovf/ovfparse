require 'rubygems'
require 'nokogiri'
require 'net/ftp'
require 'net/http'
require 'net/https'

path = File.expand_path(File.dirname(__FILE__))

require path + '/ovfparse/vmrepository'
require path + '/ovfparse/vmpackage'
require path + '/ovfparse/os_id_table'
require path + '/ovfparse/esx4_vmrepository'
require path + '/ovfparse/file_vmrepository'
require path + '/ovfparse/ftp_vmrepository'
require path + '/ovfparse/http_vmrepository'
require path + '/ovfparse/https_vmrepository'
require path + '/ovfparse/vc4_vmrepository'
