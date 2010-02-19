class Esx4VmRepository < VmRepository

  def VmRepository.ESXParse(raw_file_list) 
    file_list = Array.new 
    raw_file_list.each { |text_line|
      if text_line.include? "Name:" then
        fragment_arr = text_line.split(" ")
        file = fragment_arr.last 
        file_list.push(file)
      end
    }
    return file_list
  end


  def fetch
    if protocol.name != "esx4" then 
      return 'error'
    end

    #retrieve data from filesystem
    $cmd = VMWARE_LIBS + "/vminfo.pl --url https://" + url + "/sdk/vimService --fields vmname --folder " + VC_FOLDER + " --username " + VC_USER + " --password " + VC_PASS 

    pipe = IO.popen $cmd
    raw_file_list = pipe.read
    pipe.close
     
    #parse out package list
    package_list = VmRepository::ESXParse(raw_file_list)
    
    #construct package objects based on results
    return simplePackageConstruction(package_list)
  end
end
