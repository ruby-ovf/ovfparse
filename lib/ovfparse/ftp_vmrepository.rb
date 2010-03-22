class FtpVmRepository < VmRepository

  def VmRepository.FTParse (raw_text_arr)
    file_list = Array.new
    raw_text_arr.each { |file_text| 
      ALLOWABLE_PKG_TYPES.each { |type| 
        if file_text.include? type then
            fragment_arr = file_text.split(" ")
            file = fragment_arr.last
            file_list.push(file)
          break;
        end
      }
    }
    return file_list    
  end

  def get 
    #TODO slap a '/' char on the end of self.uri if it doesn't have one, otherwise many servers return 403 
    ftp = Net::FTP.new(url.split("/", 2)[0], "anonymous", "cops-bot@mitre.org")
    ftp.passive = true
    ftp.chdir(url.split("/", 2)[1])
    raw_text_arr = ftp.list()
    ftp.quit()
    return raw_text_arr
  end

  def fetch
    #retrieve data from ftp server
    raw_text_arr = get 

    if (raw_text_arr) 
      #parse out package list from index html
      package_list = VmRepository::FTParse(raw_text_arr)

      #construct package objects based on results
      return simplePackageConstruction(package_list)
    end
  end

end
