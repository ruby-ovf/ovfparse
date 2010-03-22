class HttpVmRepository < VmRepository

  def VmRepository.HTTParse (raw_html) 
    file_list = Array.new
    raw_html.each("</a>") { |file_text| 
      ALLOWABLE_PKG_TYPES.each { |type| 
        if file_text.include? type then
            fragment = file_text.split("</a>")
            split_expr = (type + "\">")
            file = fragment[0].split(split_expr)
            file_list.push(file[1])
          break
        end
      }          
    }
    return file_list
  end


  def get 
    #TODO slap a '/' char on the end of self.uri if it doesn't have one, otherwise many servers return 403 
    url = URI.parse(URI.escape(self.uri))
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    res.body
  end


  def fetch
    #retrieve data from http server
    if (raw_html = get)  

      #parse out package list from index html
      package_list = VmRepository::HTTParse(raw_html) 
  
      #construct package objects based on results
      return simplePackageConstruction(package_list)
    end
  end

end
