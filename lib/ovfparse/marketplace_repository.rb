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
    raw_html = open(uri)
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
