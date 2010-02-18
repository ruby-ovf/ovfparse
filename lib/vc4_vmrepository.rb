class Vc4VmRepository < VmRepository
  def initialize
  end

  def vcPackageConstruction(raw_file_list) 
    packages = Array.new 
    
    cur_name = ''
    cur_template = "0"
    cur_guest = ''

    raw_file_list.each { |text_line|
      # signifies a new group of information about a machine
      if text_line=="\n" then 
        cur_name = ''
        cur_template = "0"
        cur_guest = ''
        cur_path = ''
      elsif text_line.include? "vmPathName" then
        fragment_arr = text_line.split(" ")
        cur_path = fragment_arr.last 
#puts "vmPathName<" + text_line  + "|" + cur_path + ">"
      elsif text_line.include? "Name:" then
        fragment_arr = text_line.split(" ")
        cur_name = fragment_arr.last 
#puts "Name<" + text_line  + "|" + cur_name + ">"
      elsif text_line.include? "Template:"
        fragment_arr = text_line.split(" ")
        cur_template = fragment_arr.last
#puts "Template<" + text_line  + "|" + cur_template + ">"
      elsif text_line.include? "Guest OS:"
        fragment_arr = text_line.split("Guest OS:")
        cur_guest = fragment_arr.last.strip!
#puts "Guest<" + text_line  + "|" + cur_guest + ">"
        if cur_template=="1"
          package = Package.new
          package.name = cur_name
          package.description = 'no description available'
          package.guest_os = cur_guest
          package.uri = "jbtest" #self.uri + "/" + path
          package.version = 'Unknown'
          package.state_id = 1
          package.repository_id = id   
          packages.push(package)
        end 
      else
        #noop
      end
    }
    return packages
  end


  def fetch
    if protocol.name != "vc4" then 
      return 'error'
    end

    #retrieve data from filesystem
    $cmd = VMWARE_LIBS + "/vminfo.pl --url https://" + url + "/sdk/vimService --host xenadu1.mitre.org --folder " + VC_FOLDER + " --username " + VC_USER + " --password " + VC_PASS
    pipe = IO.popen $cmd
    raw_file_list = pipe.read
    pipe.close

    #parse out package list
    package_list = vcPackageConstruction(raw_file_list)
     
    return package_list  
    #construct package objects based on results
    #return simplePackageConstruction(package_list)
  end
end
