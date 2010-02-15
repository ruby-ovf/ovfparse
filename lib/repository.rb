require 'rubygems'
require 'net/ftp'

class Repository < ActiveRecord::Base
  belongs_to :protocol
  has_many :packages


  STRICT_CHECKING = true
  USE_CACHE = true
  ALLOWABLE_TYPES  = ["iso", "ovf", "vmx"]
  
  def uri
    if (nil==protocol) then
      return url
    else 
      return (protocol.name + "://" + url)
    end
  end

  def simplePackageConstruction(package_list) 
      packages = Array.new 
      package_list.each { |p| 
        package = Package.new
        package.name = p
        package.uri = uri + "/" + p
        package.version = 'Unknown'
        package.state_id = 1
        package.repository_id = id   
       
        packages.push(package)
      }
    return packages
  end


  def fetch
    if protocol.name=='ftp'
puts "\n******* FTP *******\n"
    elsif protocol.name=='http'
puts "\n******* HTTP *******\n"
    elsif protocol.name=='https'
puts "\n******* HTTPS *******\n"
    elsif protocol.name=='file'
puts "\n******* FILE *******\n"
    elsif protocol.name^='esx'
puts "\n******* ESX *******\n"
    elsif protocol.name^='vc'
puts "\n******* VC *******\n"
    else 
puts "\n******* UNKNOWN: " + protocol.name + " *******\n"
    end
  end

end
