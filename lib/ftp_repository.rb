require 'net/ftp'

class FtpRepository < Repository

  def Repository.FTParse (raw_text_arr)
    file_list = Array.new
    raw_text_arr.each { |file_text| 
      ALLOWABLE_TYPES.each { |type| 
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



  def fetch
    #retrieve data from ftp server
    ftp = Net::FTP.new(url.split("/", 2)[0], "anonymous", "cops-bot@mitre.org")
    ftp.passive = true
    ftp.chdir(url.split("/", 2)[1])
    raw_text_arr = ftp.list()
    ftp.quit()

    if (raw_text_arr) 
      #parse out package list from index html
      package_list = Repository::FTParse(raw_text_arr)

      #construct package objects based on results
      return simplePackageConstruction(package_list)
    end
  end

end
