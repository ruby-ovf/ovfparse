class VmPackage 
  @url
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

  attr_accessor :url, :name, :version, :state, :protocol, :size, :xml


  def initialize 
  end 

  def to_s 
#    (@name + " from " + @url + "\n")
    self.uri 
  end

  def uri 
    if (nil==@protocol) then
      return @url
    else 
      return (@protocol + "://" + @url)
    end
  end

  def initialize(uri)
    (@protocol, @url) = uri.split(":", 2) unless !uri
    @url.sub!(/^\/{0,2}/, '')
    @protocol.downcase
    @url.downcase
    @name = uri.split('/').last
  end 

  def self.create uri
    (@protocol, @url) = uri.split(":", 2) unless !uri
    @url.sub!(/^\/{0,2}/, '')
    @protocol.downcase
    @url.downcase

    if @protocol=='ftp'
      FtpVmPackage.new(uri)
    elsif @protocol=='http'
      HttpVmPackage.new(uri)
    elsif @protocol=='https'
      HttpsVmPackage.new(uri)
    elsif @protocol=='file'
      FileVmPackage.new(uri)
    elsif @protocol.match(/esx/)
      if @protocol.match(/esx4/)
        Esx4VmPackage.new(uri)
      else
        raise NotImplementedError, "Cannot handle this version of ESX: " + @protocol + "\n"
      end
    elsif @protocol.match(/vc/)
      if @protocol.match(/vc4/)
        Vc4VmPackage.new(uri)
      else
        raise NotImplementedError, "Cannot handle this version of VirtualCenter: " + @protocol + "\n"
      end
    else
      raise NotImplementedError, "Unknown Protocol: " + @protocol + " (bad URI string?)\n"
      VmRepository.new(uri)
    end
  end


  def fetch
  end

  def method_missing(method)
    puts "WARNING: NoSuchMethod Error: " + method.to_s + " ...trying XPath query \n"
  
    # try with namespace
    data = @xml.xpath("//ovf:" + method.to_s)


    # try without namespace
    if nil===data then
      data = @xml.xpath("//" + method.to_s)
    end

    # try changing method name without namespace
    # i.e. egg_and_ham.classify #=> "EggAndHam"
    if nil==data then
      data = @xml.xpath("//" + method.to_s.classify)
    end

    # try changing method name with namespace
    # i.e. egg_and_ham.classify #=> "EggAndHam"
    if nil==data then
      data = @xml.xpath("//ovf:" + method.to_s.classify)
    end

    return data

  end


end 

class HttpVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    Net::HTTP.start(url.host) { |http|
      resp = http.get(url.path)
      open(@name, "wb") { |file|
        file.write(resp.body)
      }
    }

    @xml = Nokogiri::XML(File.open(@name)) do |config|
      config.strict.noent
      config.strict
    end

    File.unlink(@name)   
  end
end

class HttpsVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    http = Net::HTTP.new(url.host, url.port)
    req = Net::HTTP::Get.new(url.path)
    http.use_ssl = true
    response = http.request(req)
    open(@name, "wb") { |file|
      file.write(response.body)
    }

    @xml = Nokogiri::XML(File.open(@name)) do |config|
#      config.options = Nokogiri::XML::ParseOptions.STRICT | Nokogiri::XML::ParseOptions.NOENT
      config.strict.noent
      config.strict
    end
  
    File.unlink(@name)   
  end


end

class FtpVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    ftp = Net::FTP.new(url.host, "anonymous", "cops-bot@mitre.org")
      ftp.passive = true
      ftp.getbinaryfile(url.path, @name, 1024)
    ftp.quit()

    @xml = Nokogiri::XML(File.open(@name)) do |config|
      config.strict.noent
      config.strict
    end
  
    File.unlink(@name)   
  end 
end

class FileVmPackage < VmPackage
  def  fetch
    @xml = Nokogiri::XML(File.open(self.url)) do |config|
      config.strict.noent
      config.strict
    end
  end
end

class Esx4VmPackage < VmPackage
end

class Vc4VmPackage < VmPackage
end
