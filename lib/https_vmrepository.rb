require 'net/ftp'
require 'http_vmrepository'

class HttpsVmRepository < HttpVmRepository
  def initialize
  end

  def fetch
      #retrieve data from http server
      if (raw_html = VmRepository.get(uri))  

        #parse out package list from index html
        package_list = VmRepository::HTTParse(raw_html) 

        #construct package objects based on results
        return simplePackageConstruction(package_list)
      end
  end

end
