class VmPackage 
  @uri
  @name
  @version
 
  UNKNOWN = 0
  INSTALLED = 1
  NOT_INSTALLED = 2
  UNINSTALLED = 3
  COPYING = 4
  BOOTING = 5
  CONFIGURING = 6 

  @state = UNKNOWN

  attr_reader :uri, :name, :version, :state 
  attr_writer :uri, :name, :version, :state

  def initialize 
  end 

  def to_s 
    puts @name + " from " + @uri
  end

end 
