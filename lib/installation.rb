class Installation < ActiveRecord::Base
  belongs_to :package
  belongs_to :workspace
  belongs_to :type
  belongs_to :function


  def poweron
    $cmd = VMWARE_LIBS + "/vmcontrol.pl --url https://e540vc.mitre.org/sdk/vimService --username " + VC_USER + " --password " + VC_PASS + " --vmname " + self.hostname  + " --operation poweron" 

    pipe = IO.popen $cmd
    raw_file_list = pipe.read
    pipe.close
  end

  def poweroff
    #retrieve data from filesystem
    $cmd = VMWARE_LIBS + "/vmcontrol.pl --url https://e540vc.mitre.org/sdk/vimService --username " + VC_USER + " --password " + VC_PASS + " --vmname " + self.hostname  + " --operation poweroff" 

    pipe = IO.popen $cmd
    raw_file_list = pipe.read
    pipe.close
  end


end
