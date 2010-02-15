require 'net/ftp'

class HttpsRepository < Repository

  def fetch
      #retrieve data from http server
      if (raw_html = Repository.get(uri))  

        #parse out package list from index html
        package_list = HttpsRepository::HTTParse(raw_html) 

        #construct package objects based on results
        return simplePackageConstruction(package_list)
      end
  end

end
