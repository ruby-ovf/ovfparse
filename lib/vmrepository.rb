
class VmRepository

  STRICT_CHECKING = true
  USE_CACHE = true
  ALLOWABLE_PKG_TYPES = ["ovf", "vmx", "ova"]
  ALLOWABLE_PROTOCOLS = ["ftp", "http", "https", "file", "smb", "esx4", "vc4"] 

  @url = ''
  @protocol = ''

  attr_writer :url, :protocol
  attr_reader :url, :protocol, :repo

def initialize(uri)
    (@protocol, @url) = uri.split(":", 2)
    @url.sub!(/^\/*/, '')
    @protocol.downcase
    @url.downcase
end 

  def self.create uri
    (@protocol, @url) = uri.split(":", 2)
    @url.sub!(/^\/*/, '')
    @protocol.downcase
    @url.downcase

    if @protocol=='ftp'
      require 'ftp_vmrepository'
      FtpVmRepository.new(uri) 
    elsif @protocol=='http'
      require 'http_vmrepository'
      HttpVmRepository.new(uri) 
    elsif @protocol=='https'
      require 'https_vmrepository'
      HttpsVmRepository.new(uri) 
    elsif @protocol=='file'
      require 'file_vmrepository'
      FileVmRepository.new(uri) 
    elsif @protocol.match(/esx/)
      if @protocol.match(/esx4/) 
        require 'esx4_vmrepository'
        Esx4VmRepository.new(uri) 
      else 
        raise NotImplementedError, "Cannot handle this version of ESX: " + @protocol + "\n"
      end
    elsif @protocol.match(/vc/)
      if @protocol.match(/vc4/) 
        require 'vc4_vmrepository'
        Vc4VmRepository.new(uri) 
      else 
        raise NotImplementedError, "Cannot handle this version of VirtualCenter: " + @protocol + "\n"
      end
    else 
      raise NotImplementedError, "Unknown Repository Protocol: " + @protocol + "\n"
      VmRepository.new(uri) 
    end
  end

  def uri 
    if (nil==protocol) then
      return url
    else 
      return (protocol + "://" + url)
    end
  end

  def fetch 
  end

  def simplePackageConstruction(package_list)
    require 'vmpackages'
    packages = Array.new
    package_list.each { |p|
      package = VmPackage.new
      package.name = p
      package.uri = uri + "/" + p
      package.version = 'Unknown'
      package.state = VmPackage::UNKNOWN 
#      package.repository_id = id

      packages.push(package)
    }

    return packages

  end

  def get 
  end

end
