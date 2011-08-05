require 'nokogiri'
require 'open-uri'

class MarketplaceRepository < VmRepository

  def parse (raw_html) 
    file_list = Array.new
    
    xml = Nokogiri::XML(raw_html) do |config|
      config.noblanks.strict.noent
    end

    entries = xml.root.children.select { |element| element.name == 'entry' }

    entries.each { |entry|
       repository = entry.children.detect { |element| element.name == 'repository' }
       basepath = repository.children.detect { |element| element.name == 'basepath' }
       filename = repository.children.detect { |element| element.name == 'filename' }

       file_list.push( {'basepath' => basepath.content, 'filename' => filename.content} )
    }

    return file_list
  end

  def fetch
    #retrieve data from http server
    begin
      raw_html = open(uri)
    rescue
      if(uri.match(/\/$/) != nil)
        begin
          raw_html = open(uri[0..-2])
          @url = @url[0..-2]
        rescue Exception => e
          #something useful
          raise "Tried getting rid of the trailing slash but still no dice: " + e.message
        end
      else
        #something useful
        raise "No trailing slash so this is probably a dead URL"
      end
    end
    if (raw_html)  

      #parse out package list from index html
      package_list = parse(raw_html) 
  
      #construct package objects based on results
      return listPackages(package_list)
    end
  end

  def listPackages(package_list)
    packages = Array.new
    package_list.each { |pkg|
      fullpath = (pkg['basepath'] + pkg['filename']).to_s
      package = VmPackage.create(fullpath)
      package.base_path = pkg['basepath']
      package.name = pkg['filename']

      packages.push(package)
    }

    return packages
  end

end
