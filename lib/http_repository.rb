require 'net/ftp'

class HttpRepository < Repository

  def Repository.HTTParse (raw_html) 
    file_list = Array.new
    raw_html.each("</a>") { |file_text| 
      ALLOWABLE_TYPES.each { |type| 
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



  def fetch
    #retrieve data from http server
    if (raw_html = Repository.get(uri))  

      #parse out package list from index html
      package_list = Repository::HTTParse(raw_html) 
  
      #construct package objects based on results
      return simplePackageConstruction(package_list)
    end
  end

end
