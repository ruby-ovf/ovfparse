require 'rubygems'
require 'net/ftp'

class VmRepository

  STRICT_CHECKING = true
  USE_CACHE = true
  ALLOWABLE_PKG_TYPES = ["ovf", "vmx"]
  ALLOWABLE_PROTOCOLS = ["ftp", "http", "https", "file", "smb", "esx4", "vc4"] 

  @url = ''
  @protocol = ''
  @repo = nil

  attr_writer :url, :protocol
  attr_reader :url, :protocol, :repo

  def initialize(uri)
    (@protocol, @url) = uri.split(":", 2)
    @url.sub!(/^\/*/, '')
    @protocol.downcase
    @url.downcase

    if @protocol=='ftp'
      require 'ftp_vmrepository'
      @repo = FtpVmRepository.new 
    elsif @protocol=='http'
      require 'http_vmrepository'
      @repo = HttpVmRepository.new 
    elsif @protocol=='https'
      require 'https_vmrepository'
      @repo = HttpsVmRepository.new 
    elsif @protocol=='file'
      require 'file_vmrepository'
      @repo = FileVmRepository.new 
    elsif @protocol.match(/esx/)
puts "%%%%%%%%%%  " + @protocol + " %%%%%%%%%\n"
      if @protocol.match(/esx4/) 
        require 'esx4_vmrepository'
        @repo = Esx4VmRepository.new 
      else 
        raise NotImplementedError, "Cannot handle this version of ESX: " + @protocol + "\n"
      end
    elsif @protocol.match(/vc/)
      if @protocol.match(/vc4/) 
        require 'vc4_vmrepository'
        @repo = Vc4VmRepository.new 
      else 
        raise NotImplementedError, "Cannot handle this version of VirtualCenter: " + @protocol + "\n"
      end
    else 
      raise NotImplementedError, "Unknown Repository Protocol: " + @protocol + "\n"
    end
  end

  def uri 
    if (nil==protocol) then
      return url
    else 
      return (protocol + "://" + url)
    end
  end

  def fetch (uri)
  end

end
