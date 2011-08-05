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
    begin
      url = URI.parse(URI.escape(self.uri))
      req = Net::HTTP::Get.new(url.path)
    rescue
      if(uri.match(/\/$/) == nil)
        begin
          url = URI.parse(URI.escape(self.uri + '/'))
          req = Net::HTTP::Get.new(url.path)
          @url = @url + '/'
        rescue Exception => e
          raise "We tried it with and without a trailing / but it still doesn't work, this thing is broken: " + e.message
          # TODO: log the fact that this repo sucks at life
        end
      else
        raise "This has a trailing slash and it doesn't work so it's a busted URL"
      end
    end

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
