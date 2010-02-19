require 'rubygems'
require 'nokogiri'

class VmPackage 
  @uri
  @name
  @version
  @protocol
  @size 
  @xml 

  OVA = 0
  OVF = 1
  ISO = 2
  
  @type = nil
 
  UNKNOWN = 0
  INSTALLED = 1
  NOT_INSTALLED = 2
  UNINSTALLED = 3
  COPYING = 4
  BOOTING = 5
  CONFIGURING = 6 

  @state = UNKNOWN

  attr_reader :uri, :name, :version, :state, :protocol, :size, :xml 
  attr_writer :uri, :name, :version, :state, :protocol, :size, :xml

  def initialize 
  end 

  def to_s 
    (@name + " from " + @uri + "\n")
  end


  def self.create protocol
    @protocol = protocol

    if @protocol=='ftp'
      FtpVmPackage.new
    elsif @protocol=='http'
      HttpVmPackage.new
    elsif @protocol=='https'
      HttpsVmPackage.new
    elsif @protocol=='file'
      FileVmPackage.new
    elsif @protocol.match(/esx/)
      if @protocol.match(/esx4/)
        require 'esx4_vmrepository'
        Esx4VmPackage.new
      else
        raise NotImplementedError, "Cannot handle this version of ESX: " + @protocol + "\n"
      end
    elsif @protocol.match(/vc/)
      if @protocol.match(/vc4/)
        require 'vc4_vmrepository'
        Vc4VmPackage.new
      else
        raise NotImplementedError, "Cannot handle this version of VirtualCenter: " + @protocol + "\n"
      end
    else
      raise NotImplementedError, "Unknown Repository Protocol: " + @protocol + "\n"
      VmRepository.new
    end
  end


  def get
  end

end 

class HttpVmPackage < VmPackage
end

class HttpsVmPackage < VmPackage
end

class FtpVmPackage < VmPackage
  def get 
    require 'net/http'
    url = URI.parse(@uri)
    ftp = Net::FTP.new(url.host, "anonymous", "cops-bot@mitre.org")
      ftp.passive = true
      ftp.getbinaryfile(url.path, @name, 1024)
    ftp.quit()

    f = File.open(@name)
      doc = Nokogiri::XML(f)
    f.close
     
    puts f  
  end 
end

class FileVmPackage < VmPackage
end

class Esx4VmPackage < VmPackage
end

class Vc4VmPackage < VmPackage
end
