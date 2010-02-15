class Package < ActiveRecord::Base
require "digest/sha1"


#  column :name, :string
#  column :uri, :string
#  column :version, :string
#  column :installed, :boolean 
 
# You really killed me with this one, Jim.   -- Mike.
#  CACHE_REFRESH_DAYS = 0.5
  # 0.0001736 = 15 seconds (1 day / 24 hrs / 60 mins / 4)
#  CACHE_REFRESH_DAYS = 0.0001736
#  CACHE_REFRESH_DAYS = 0.0208 #(1 day / hrs / 2 ) = every 30 minutes
  CACHE_REFRESH_DAYS = 3

  belongs_to :repository
  belongs_to :state
  has_many   :installations
  has_many   :dependencies,     :class_name => 'Deps', :foreign_key => 'package_id' 
  has_many   :depended_upon_by, :class_name => 'Deps', :foreign_key => 'dependency_id'

  has_and_belongs_to_many :parameters

#  has_friendly_id :name, :use_slug => true

  attr_reader :uri
  attr_writer :uri

#  def initialize(name, uri, version, installed) 
#    @id = name   
#    @name = name
#    @uri  = uri
#    @version = version
#    @installed = installed
#  end 

  def Package.fetch
    packages = Array.new 
    repositories = Repository.find(:all)
    repositories.map { |repository|
      if ((repository.refresh_date==nil) ||
          (repository.refresh_date<(DateTime.now - CACHE_REFRESH_DAYS)))
          packages = repository.fetch  

          repository.refresh_date = DateTime.now 
          repository.save!
          # now check to make sure we don't have this package already 
          packages.each { |new_package| 
            package = Package.find_by_name_and_repository_id(new_package.name, repository.id)
            if nil==package then 
              new_package.save!
            end 
          }

      else 
#          final_packages += repository.packages
      end
    }
    final_packages = Package.find(:all)
    return final_packages
  end

  def install(workspace_id) 
    # Status to return as output
    $retval = "Unknown"

    # adjust state to "installing"
#    puts "\n\n-----------------\n* adjusting state \n"
#    self.state_id = 4
    self.save!

    # Get the package name
    $source_vmname = name
  
    # Generate unique clone name 
    unique_key = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..10]
    $clone_vmname = $source_vmname + "_" + unique_key.to_s 
puts "\n#####################################\n"
puts $clone_vmname + " | " + workspace_id.to_s + " | " + self.id.to_s + "\n"
puts "\n#####################################\n"
    installation = Installation.create(:hostname => $clone_vmname, :workspace_id => workspace_id, :type_id => 2, :package_id => self.id)
    #cheap hack for vnc port for now, just 5000 + id of installation record
    vnc_port = 5000 + installation.id 
    installation.vnc_uri = "http://" + COPS_GW.to_s + ":" + vnc_port.to_s
    installation.save!

    # Clone this package
#    puts "\n\n--------------------------------------\n* Cloning for " + $clone_vmname.to_s + " started at " + Time.now().to_s

    # Temporary file for status information
    $temp_output = %{/tmp/#{$clone_vmname}.txt}
    %x[rm #{$temp_output} 2> /dev/null]

# TODO: use this env. var.
#VMWARE_LIBS = '/usr/lib/vmware-vcli/apps/vm/'

    # Attempt to clone the machine
    $result = %x[/usr/lib/vmware-vcli/apps/vm/vmclone.pl  \\
	--vmname #{$source_vmname} \\
	-vmname_destination #{$clone_vmname} \\
	--vmhost xenadu1.mitre.org \\
	--datastore xenadu-disk2 \\
	--server #{%Q[#{VC_SERVER}].sub(/\\/,"\\\\\\\\")} \\
	--username #{%Q[#{VC_USER}].sub(/\\/,"\\\\\\\\")} \\
	--password #{%Q[#{VC_PASS}].sub(/\\/,"\\\\\\\\")} \\
	2>&1 | tee -a #{$temp_output}]

    $exitstatus = $?.exitstatus

    # Escape carriage returns- %x won't work otherwise
#    puts "\nResult from cloning: #{$result}"
#    puts "\nExit status from cloning: #{$exitstatus}"

    # Test for vmclone.pl errors
    if $exitstatus == 0

      # Test for VCenter errors
      #
      counter = 1

      if /successfully created/.match($result)
#        puts "\nSuccessfully created!"
        $retval = "Cloned"

        # Boot up the new virtual machine
        $boot_result = %x[/usr/lib/vmware-vcli/apps/vm/vmcontrol.pl  \\
		--vmname #{$clone_vmname}  \\
		--server #{%Q[#{VC_SERVER}].sub(/\\/,"\\\\\\\\")} \\
		--username #{%Q[#{VC_USER}].sub(/\\/,"\\\\\\\\")} \\
		--password #{%Q[#{VC_PASS}].sub(/\\/,"\\\\\\\\")} \\
		--operation poweron ]
        $exitstatus = $?.exitstatus

#        puts "\nExit status from power-on: #{$exitstatus}"

        if /powered on/.match($boot_result)
          $retval = "Installed"
#          self.state_id = 2
          self.save!

#        elsif //.match($boot_result)
#          $retval = "Cloned, but could not power on"
        else
          $retval = "Cloned, with unknown boot status"
        end
        
      elsif /already exists/.match($result)
        # This error appears when the target name of a cloned machine is
        # already in use
#        puts "Error: clone already exists"
        $retval = "Already exists"

      elsif /No virtual machine found with name/.match($result)
        # This occurs if the URI requested contains the name of a package
        # which does not exist
#        puts "Error: Source machine not found: #{$source_vmname}"
        $retval = "Source VM not found - " + $source_vmname

      elsif /incorrect user name or password/.match($result)
        # This occurs if the login credentials are inaccurate
#        puts "Error: bad username/password"
        $retval = "Bad username/password"

      elsif /Unable to communicate with the remote host/.match($result)
        # This occurs if the login credentials are inaccurate
#        puts "Error: cannot connect to server"
        $retval = "Cannot connect to server"

      else
        # TODO: Excecution should never reach here
        #       Something terrible must have happened
#        puts "Unknown cloning error: #{$foobar}"
        $retval = "Unknown cloning error: " + $foobar.to_s 
      end

    elsif $exitstatus == 127

      # Failure here indicates that the command could not be found 
      # (e.g.:  "sh: /usr/lib/vmware-vcli/apps/vm/vmclone.pl: not found")
      $retval = "VMWare CLI not installed"
#      puts "\nVMWare CLI not found (#{$exitstatus})"

    else

      # Failure here indicates that the command line arguments supplied were rejected
      # The $temp_output file will likely have Usage information for vmclone.pl as output
      $retval = "Error in cloning (" + $exitstatus.to_s + "): " + $result
#      puts "Failed"
    end

#    %x[echo Cloning request ended at `date` >> #{$OUTPUT_FILE}]
#    puts "Cloning request ended at " + Time.now().to_s + "\n--------------------------------------"

    return $retval
  end 

  def uninstall(workspace_id)
    installation = Installation.find_by_workspace_id_and_package_id(workspace_id, self.id)
#    installation.destroy!
   
#    self.state_id = 5
#    self.save!

#    installation = self.installations.first 

#    installation.poweroff

#    self.state_id = 3
#    self.save!
  end 

  def reinstall
#    self.state_id = 5
    self.save!

    installation = self.installations.first 

    installation.poweron

#    self.state_id = 2
    self.save!
  end 

end
