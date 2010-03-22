class FileVmRepository < VmRepository

  def VmRepository.LSParse (raw_file_text) 
    file_list = Array.new 
    raw_file_text.each { |file_text|
      ALLOWABLE_PKG_TYPES.each { |type| 
        if file_text.include? type then
          fragment_arr = file_text.split(" ")
          file = fragment_arr.last
          file_list.push(file)
        end
      }
    }
    return file_list 
  end

  def get 
    #TODO slap a '/' char on the end of self.uri if it doesn't have one, otherwise many servers return 403 
    #if linux
    $cmd = "ls " + @url
    #if windows
    #$cmd = "dir " + url
    #

    pipe = IO.popen $cmd
    raw_file_list = pipe.read
    pipe.close
      
      return raw_file_list 
  end 


  def fetch 
      #retrieve data from file system 
      raw_file_list = get

      #parse out package list
      #if linux 
      package_list = VmRepository::LSParse(raw_file_list)
      #if windows 
      #package_list = Repository::DIRParse(file_list)
    
      #construct package objects based on results
      return simplePackageConstruction(package_list)
  end
end
