require 'open-uri'

class VmPackage 
  @url
  @base_path
  @name
  @version
  @protocol
  @size 
  @xml 
  

  OVA = 0
  OVF = 1
  ISO = 2

  @references
  @diskSection
  @networkSection
  @virtualSystem
  
  @type = nil

  DEBUG_MODE = false

  # List of attributes in an OVF product that we will extract / set
  PRODUCT_ATTRIBUTES = [ {'full_name' => 'ovf:instance', 'node_ref' => 'instance', 'attribute_ref' => 'instance'},
                         {'full_name' => 'ovf:class', 'node_ref' => 'class', 'attribute_ref' => 'product_class'} ]

  # List of elements in an OVF product that we will extract / set
  PRODUCT_ELEMENTS = [ {'full_name' => 'Info', 'node_ref' => 'Info', 'element_ref' => 'description', 'required' => false},
                       {'full_name' => 'Product', 'node_ref' => 'Product', 'element_ref' => 'name', 'required' => false},
                       {'full_name' => 'Vendor', 'node_ref' => 'Vendor', 'element_ref' => 'vendor', 'required' => false},
                       {'full_name' => 'Version', 'node_ref' => 'Version', 'element_ref' => 'version', 'required' => false} ]

  # List of attributes in an OVF property that we will extract / set
  PROPERTY_ATTRIBUTES = [ {'full_name' => 'ovf:value', 'node_ref' => 'value', 'attribute_ref' => 'value'},
                          {'full_name' => 'ovf:key', 'node_ref' => 'key', 'attribute_ref' => 'key'},
                          {'full_name' => 'ovf:userConfigurable', 'node_ref' => 'userConfigurable', 'attribute_ref' => 'userConfigurable'},
                          {'full_name' => 'ovf:password', 'node_ref' => 'password', 'attribute_ref' => 'password'},
                          {'full_name' => 'ovf:required', 'node_ref' => 'required', 'attribute_ref' => 'required'},
                          {'full_name' => 'ovf:type', 'node_ref' => 'type', 'attribute_ref' => 'value_basetype'},
                          {'full_name' => 'cops:valueType', 'node_ref' => 'valueType', 'attribute_ref' => 'valueType'}, # @todo refactor to cops extension module
                          {'full_name' => 'cops:uuid', 'node_ref' => 'uuid', 'attribute_ref' => 'uuid'} ] # @todo refactor to cops extension module

  # List of elements in an OVF property that we will extract / set
  PROPERTY_ELEMENTS = [ {'full_name' => 'Label', 'node_ref' => 'Label', 'element_ref' => 'name', 'required' => false},
                        {'full_name' => 'Description', 'node_ref' => 'Description', 'element_ref' => 'description', 'required' => false},
                        {'full_name' => 'Example', 'node_ref' => 'cops:Example', 'element_ref' => 'example', 'required' => true}, # @todo refactor to cops extension module
                        {'full_name' => 'NoneType', 'node_ref' => 'cops:NoneType', 'element_ref' => 'nonetype', 'required' => true} ] # @todo refactor to cops extension module
  
  OVF_NAMESPACE = {'ovf' => 'http://schemas.dmtf.org/ovf/envelope/1'}


  attr_accessor :url, :base_path, :name, :version, :state, :protocol, :size, :xml, :references, :diskSection, :networkSection, :virtualSystem


  def initialize 
  end 

  def to_s 
#    (@name + " from " + @url + "\n")
    self.uri 
  end

  def uri 
    if (nil==@protocol) then
      return @url
    else 
      return (@protocol + "://" + @url)
    end
  end

  def initialize(uri)
    if (URI::HTTP==uri.class) then
      uri = uri.to_s 
    end

    (@protocol, @url) = uri.split(":", 2) unless !uri
    @url.sub!(/^\/{0,2}/, '')
    @protocol.downcase
    @url.downcase
    @name = uri.split('/').last
  end 

  def self.create uri
    (@protocol, @url) = uri.split(":", 2) unless !uri
    @url.sub!(/^\/{0,2}/, '')
    @protocol.downcase
    @url.downcase
    if @protocol=='ftp'
      FtpVmPackage.new(uri)
    elsif @protocol=='http'
      HttpVmPackage.new(uri)
    elsif @protocol=='https'
      HttpsVmPackage.new(uri)
    elsif @protocol=='file'
      FileVmPackage.new(uri)
    elsif @protocol.match(/esx/)
      if @protocol.match(/esx4/)
        Esx4VmPackage.new(uri)
      else
        raise NotImplementedError, "Cannot handle this version of ESX: " + @protocol + "\n"
      end
    elsif @protocol.match(/vc/)
      if @protocol.match(/vc4/)
        Vc4VmPackage.new(uri)
      else
        raise NotImplementedError, "Cannot handle this version of VirtualCenter: " + @protocol + "\n"
      end
    else
      raise NotImplementedError, "Unknown Protocol: " + @protocol + " (bad URI string?)\n"
      VmRepository.new(uri)
    end
  end


  def fetch
  end


  # Caches all of the base elements inside Envelope for fast access
  def loadElementRefs
     children = @xml.root.children

     @references = getChildByName(xml.root, 'References')
     @virtualSystem = getChildByName(xml.root, 'VirtualSystem')

     @diskSection = getChildByName(xml.root, 'DiskSection') || @virtualSystem.add_previous_sibling(xml.create_element('DiskSection', {}))
     @networkSection = getChildByName(xml.root, 'NetworkSection') || @virtualSystem.add_previous_sibling(xml.create_element('NetworkSection', {}))

  end
  
  # Returns the first child node of the passed node whose name matches the passed name.
  def getChildByName(node, childName)
     return node.nil? ? nil : node.children.detect{ |element| element.name == childName}
  end

  # Returns every child node of the passed node whose name matches the passed name.
  def getChildrenByName(node, childName)
     return node.nil? ? [] : node.children.select{ |element| element.name == childName}
  end

  def referenced_file(element) 
    @xml.xpath("//ovf:References/ovf:File[@ovf:id='#{element['fileRef']}']", OVF_NAMESPACE).first
  end
     
  def method_missing(method)
    if DEBUG_MODE
      puts "WARNING: NoSuchMethod Error: " + method.to_s + " ...trying XPath query \n"
    end 
  
    # try with namespace
    data = @xml.xpath("//ovf:" + method.to_s)


    # try without namespace
    if nil===data then
      data = @xml.xpath("//" + method.to_s)
    end

    # try changing method name without namespace
    # i.e. egg_and_ham.classify #=> "EggAndHam"
    if nil==data then
      data = @xml.xpath("//" + method.to_s.classify)
    end

    # try changing method name with namespace
    # i.e. egg_and_ham.classify #=> "EggAndHam"
    if nil==data then
      data = @xml.xpath("//ovf:" + method.to_s.classify)
    end

    return data

  end

  def checkschema(schema)
    xsd = Nokogiri::XML::Schema(File.open(schema))
    response = ""

    isValid = true    
    xsd.validate(@xml).each do |error|
      response << error.message + "\n"
      isValid = false
    end

    return [isValid, response]
  end

  def getVmName
    return virtualSystem['id'] || ''
  end

  def getVmDescription
    descNode = getChildByName(virtualSystem, 'Info')
    return descNode.nil? ? '' : descNode.content
  end

  def getVmOS_ID
    osNode = getChildByName(virtualSystem, 'OperatingSystemSection')
    return osNode.nil? ? '' : osNode['id']
  end

  def getVmOS
    os = getVmOS_ID
    return os == '' ? '' : OS_ID_TABLE[os.to_i]
  end 


  # note this is not part of the OVF spec. Specific users could overwrite this method to 
  # store/retrieve patch level in the description field, for example.
  def getVmPatchLevel
  end

  def setVmPatchlevel
  end

  def getVmAttributes
     return {
        'name' => getVmName,
        'description' => getVmDescription,
        'OS' => getVmOS_ID,
        'patch_level' => getVmPatchLevel,
        'CPUs' => getVmCPUs,
        'RAM' => getVmRAM
     }
  end

  def getVmDisks
    disks = Array.new
    filenames = Hash.new
    getChildrenByName(references, 'File').each { |node|
      filenames[node['id']] = node['href']
    }

    getChildrenByName(diskSection, 'Disk').each { |node|
      disks.push({ 'name' => node['diskId'], 'location' => filenames[node['fileRef']], 'size' => node['capacity'] })
    }

    return disks
  end

  def getVmNetworks
    networks = Array.new
    getChildrenByName(networkSection, 'Network').each { |node|
      descriptionNode = getChildByName(node, 'Description')
      text = descriptionNode.nil? ? '' : descriptionNode.text
      networks.push({'location' => node['name'], 'notes' => text })
    }
    return networks
  end


  def getVmCPUs
    return getVirtualQuantity(3)
  end

  def getVmRAM
    return getVirtualQuantity(4)
  end

  def getVirtualQuantity(resource)
    getChildrenByName(getChildByName(virtualSystem, 'VirtualHardwareSection'), 'Item').each{ |node|
      resourceType = node.xpath('rasd:ResourceType')[0].text
      resourceType == resource.to_s ? (return node.xpath('rasd:VirtualQuantity')[0].text) : next
    }
  end

  def setVmName(newValue)
    virtualSystem['ovf:id'] = newValue
    nameNode = getChildByName(virtualSystem, 'Name') ||
       getChildByName(virtualSystem, 'Info').add_next_sibling(xml.create_element('Name', {}))
    nameNode.content = newValue
  end

  def setVmDescription(newValue)
    getChildByName(virtualSystem, 'Info').content = newValue
  end

  def setVmOS_ID(newValue)
    getChildByName(virtualSystem, 'OperatingSystemSection')['ovf:id'] = newValue.to_s
  end


  def setVmCPUs(newValue)
    setVirtualQuantity(3, newValue)
  end

  def setVmRAM(newValue)
    setVirtualQuantity(4, newValue)
  end

  def setVirtualQuantity(resource, newValue)
    getChildrenByName(getChildByName(virtualSystem, 'VirtualHardwareSection'), 'Item').each { |node|
      resourceType = node.xpath('rasd:ResourceType')[0].text
      resourceType == resource.to_s ? (node.xpath('rasd:VirtualQuantity')[0].content = newValue) : next
    }
  end

  def removeNetworksFromVirtualHardwareSection
     vhs = getChildByName(virtualSystem, 'VirtualHardwareSection') || virtualSystem.add_child(xml.create_element('VirtualHardwareSection', {}))
     items = getChildrenByName(vhs, 'Item')
     items.each { |item|
        id = getChildByName(item, 'ResourceType')
        if(id.content == '10')
           item.unlink
        end
     }
  end

  def setVmNetworks(networks)
     networkNodes = getChildrenByName(networkSection, 'Network')
     vhs = getChildByName(virtualSystem, 'VirtualHardwareSection')

     networkNodes.each { |node|
        updated_network = networks.detect { |network| network.location == node['name'] }
        if(updated_network.nil?)
           node.unlink
        else
           descriptionNode = getChildByName(node, 'Description')
           if((updated_network.notes == '' || updated_network.notes.nil?) && !descriptionNode.nil?)
              descriptionNode.unlink
           elsif(updated_network.notes != '' && !updated_network.notes.nil?)
		descriptionNode = descriptionNode || descriptionNode.add_child(xml.create_element("Description", {}))
              descriptionNode.content = updated_network.notes
           end
        end
     }

     # Find the highest instance ID
     maxID = 0
     items = getChildrenByName(vhs, 'Item')
     items.each { |item|
        itemID = getChildByName(item, 'InstanceID').content.to_i
        if(itemID > maxID)
           maxID = itemID
        end
     }

     rasdNamespace = xml.root.namespace_definitions.detect{ |ns| ns.prefix == 'rasd' }
     netCount = 0

     networks.each { |network|
        if( (networkNodes.detect { |node| network.location == node['name'] }).nil?)
           networkNode = networkSection.add_child(xml.create_element('Network', {'ovf:name' => network.location}))
           if(network.notes != '' && !network.notes.nil?)
              networkNode.add_child(xml.create_element('Description', network.notes))
           end
        end

        maxID += 1
        newNetwork = vhs.add_child(xml.create_element('Item', {}))
        newNetwork.add_child(xml.create_element('AutomaticAllocation', "true")).namespace = rasdNamespace
        newNetwork.add_child(xml.create_element('Connection', network.location)).namespace = rasdNamespace
        newNetwork.add_child(xml.create_element('ElementName', "ethernet" + netCount.to_s)).namespace = rasdNamespace
        newNetwork.add_child(xml.create_element('InstanceID', maxID.to_s)).namespace = rasdNamespace
        newNetwork.add_child(xml.create_element('ResourceSubType', "E1000")).namespace = rasdNamespace
        newNetwork.add_child(xml.create_element('ResourceType', "10")).namespace = rasdNamespace
        netCount += 1
     }
  end

  def removeDisksFromVirtualHardwareSection
     vhs = getChildByName(virtualSystem, 'VirtualHardwareSection') || virtualSystem.add_child(xml.create_element('VirtualHardwareSection', {}))
     items = getChildrenByName(vhs, 'Item')
     items.each { |item|
        id = getChildByName(item, 'ResourceType')
        if(id.content == '17')
           parentID = getChildByName(item, 'Parent').content
           parent = items.detect { |potentialParent| getChildByName(potentialParent, 'InstanceID').content == parentID }
           unless parent.nil?
              parent.unlink
           end
           item.unlink
        end
     }
  end

  def setVmDisks(disks)
     removeDisksFromVirtualHardwareSection

     fileNodes = getChildrenByName(references, 'File')
     diskNodes = getChildrenByName(diskSection, 'Disk')
     vhs = getChildByName(virtualSystem, 'VirtualHardwareSection')

     icons = Array.new
     getChildrenByName(getChildByName(virtualSystem, 'ProductSection'), 'Icon').each { |node|
        icons.push(node['fileRef'])
     }

     fileNodes.each { |file_node|
        updated_disk = disks.detect { |disk| disk.location == file_node['href'] }
        old_disk_node = diskNodes.detect { |old_node| old_node['id'] == file_node['fileRef'] }

        if(updated_disk.nil?)
           if((icons.detect { |fileRef| fileRef == file_node['id'] }).nil?)
              file_node.unlink
              if(!old_disk_node.nil?)
                 old_disk_node.unlink
              end
           end
        else
           file_node['ovf:id'] = updated_disk.name + '_disk'
           old_disk_node['ovf:fileRef'] = updated_disk.name + '_disk'
           old_disk_node['ovf:capacity'] = updated_disk.size.to_s
           old_disk_node['ovf:diskId'] = updated_disk.name
        end
     }

     # Find the highest instance ID
     maxAddress = 0
     maxID = 0
     items = getChildrenByName(vhs, 'Item')
     items.each { |item|
        itemID = getChildByName(item, 'InstanceID').content.to_i
        if(itemID > maxID)
           maxID = itemID
        end

        # Find the highest address of any existing IDE controllers, for CD drives and stuff
        itemAddress = getChildByName(item, 'Address').content
        if(content != '' && content.to_i > maxAddress)
           maxAddress = content.to_i
        end
     }

     rasdNamespace = xml.root.namespace_definitions.detect{ |ns| ns.prefix == 'rasd' }

     disks.each { |disk|
        if( (fileNodes.detect { |node| disk.location == node['href'] }).nil?)
           diskSection.add_child(xml.create_element('Disk', {'ovf:capacity' => disk.size.to_s, 'ovf:capacityAllocationUnits' => "byte * 2^30", 'ovf:diskId' => disk.name, 'ovf:fileRef' => disk.name + '_disk', 'ovf:format' => "http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized" }))
           references.add_child(xml.create_element('File', {'ovf:href' => disk.location, 'ovf:id' => disk.name + '_disk'}))
        end

        maxAddress += 1
        maxID += 1
        newController = vhs.add_child(xml.create_element('Item', {}))
        newController.add_child(xml.create_element('Address', maxAddress.to_s)).namespace = rasdNamespace
        newController.add_child(xml.create_element('Description', "IDE Controller for " + disk.name)).namespace = rasdNamespace
        newController.add_child(xml.create_element('ElementName', "IDEController" + maxAddress.to_s)).namespace = rasdNamespace
        newController.add_child(xml.create_element('InstanceID', maxID.to_s)).namespace = rasdNamespace
        newController.add_child(xml.create_element('ResourceType', "5")).namespace = rasdNamespace

        maxID += 1
        newDisk = vhs.add_child(xml.create_element('Item', {}))
        newDisk.add_child(xml.create_element('AddressOnParent', "0")).namespace = rasdNamespace
        newDisk.add_child(xml.create_element('ElementName', disk.name)).namespace = rasdNamespace
        newDisk.add_child(xml.create_element('HostResource', "ovf:/disk/" + disk.name + "_disk")).namespace = rasdNamespace
        newDisk.add_child(xml.create_element('InstanceID', maxID.to_s)).namespace = rasdNamespace
        newDisk.add_child(xml.create_element('Parent', (maxID - 1).to_s)).namespace = rasdNamespace
        newDisk.add_child(xml.create_element('ResourceType', "17")).namespace = rasdNamespace
     }

  end

  def setVmAttributes(attributes)
    if attributes['name']
      setVmName(attributes['name'])
    end
    if attributes['description']
      setVmDescription(attributes['description'])
    end
    if attributes['OS']
      setVmOS_ID(attributes['OS'])
    end
    if attributes['patch_level']
      setVmPatchLevel(attributes['patch_level'])
    end
    if attributes['CPUs']
      setVmCPUs(attributes['CPUs'])
    end
    if attributes['RAM']
      setVmRAM(attributes['RAM'])
    end
  end

  def setProductIcon(new_icon, productNode)
     iconNode = getChildByName(productNode, 'Icon')
     if((new_icon == '' || new_icon.nil?) && !iconNode.nil?)
        getChildrenByName(references, 'File').detect { |fileNode| fileNode['id'] == iconNode['fileRef']}.unlink
        iconNode.unlink
     elsif(new_icon != '' && !new_icon.nil?)
        if(iconNode.nil?)
           productNode.add_child(xml.create_element('Icon', {'ovf:fileRef' => productNode['class'] + '_icon'}))
           iconRef = getChildrenByName(references, 'File').detect { |fileNode| fileNode['href'] == new_icon} ||
              references.add_child(xml.create_element('File', {'ovf:href' => new_icon}))
           iconRef['ovf:id'] = productNode['class'] + '_icon'
        else
           productNode.add_child(iconNode)
           getChildrenByName(references, 'File').detect { |fileNode| fileNode['id'] == iconNode['fileRef']}['ovf:href'] = new_icon
        end
     end
  end

  def setElements(updated_element, parent_node, element_list)
     element_list.each { |element_details|
        updated_value = updated_element[element_details['element_ref']]
        element_node = parent_node.xpath(element_details['full_name'])[0]
        #if((updated_value == '' || updated_value.nil?) && !element_node.nil?)
        #   element_node.unlink
        #elsif(updated_value != '' && !updated_value.nil?)
           element_node = element_node.nil? ? parent_node.add_child(xml.create_element(element_details['node_ref'], {})) : parent_node.add_child(element_node)
           element_node.content = updated_value || ''
           if(element_details['required'])
              element_node['ovf:required'] = 'false'
           end
       # end
     }
  end

  def setAttributes(updated_element, parent_node, attribute_list)
     attribute_list.each { |attribute_details|
        updated_value = updated_element[attribute_details['attribute_ref']]
       # (updated_value == '' || updated_value.nil?) ? parent_node.delete(attribute_details['node_ref']) :
        parent_node[attribute_details['full_name']] = updated_value || ''
     }
  end


  # @todo any need to make this a general purpose "writer" ?
  def self.construct_skeleton
     builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.Envelope('xmlns' => 'http://schemas.dmtf.org/ovf/envelope/1', 'xmlns:cim' => "http://schemas.dmtf.org/wbem/wscim/1/common", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1", 'xmlns:rasd' => "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData", 'xmlns:vmw' => "http://www.vmware.com/schema/ovf", 'xmlns:vssd' => "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData", 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance") {
          xml.References{}
          xml.DiskSection{
             xml.Info "Virtual disk information"
          }
          xml.NetworkSection{
             xml.Info "List of logical networks"
          }
          xml.VirtualSystem('ovf:id' => "vm"){
             xml.Info "A virtual machine"
             xml.Name "New Virtual Machine"
             xml.OperatingSystemSection('ovf:id' => "94"){
                 xml.Info "The kind of guest operating system"
             }
             xml.VirtualHardwareSection{
                 xml.Info "Virtual hardware requirements"
                 xml.System{
                     xml['vssd'].ElementName "Virtual Hardware Family"
                     xml['vssd'].InstanceID "0"
                     xml['vssd'].VirtualSystemIdentifier "New Virtual Machine"
                 }
                 xml.Item{
                     xml['rasd'].AllocationUnits "herts * 10^6"
                     xml['rasd'].Description "Number of Virtual CPUs"
                     xml['rasd'].ElementName "1 Virtual CPU(s)"
                     xml['rasd'].InstanceID "1"
                     xml['rasd'].ResourceType "3"
                     xml['rasd'].VirtualQuantity "1"
                 }
                 xml.Item{
                     xml['rasd'].AllocationUnits "byte * 2^20"
                     xml['rasd'].Description "Memory Size"
                     xml['rasd'].ElementName "512MB of memory"
                     xml['rasd'].InstanceID "2"
                     xml['rasd'].ResourceType "4"
                     xml['rasd'].VirtualQuantity "512"
                 }
             }
          }
      }

      node = Nokogiri::XML::Comment.new(xml.doc, ' skeleton framework constructed by OVFparse ')
      xml.doc.children[0].add_previous_sibling(node)
    end

    newPackage = NewVmPackage.new
    newPackage.xml = builder.doc
    newPackage.loadElementRefs
    return newPackage
  end

  def write_xml(file)
    xml.write_xml_to(file)
  end

  # @todo make this a general purpose signing util
  def sign(signature)
    node = Nokogiri::XML::Comment.new(xml, signature)
    xml.children[0].add_next_sibling(node)
  end

  def xpath(string)
    puts @xml.xpath(string)
  end

end 

class HttpVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    
    @xml = Nokogiri::XML(open(url)) do |config|
      config.noblanks.strict.noent
    end

    loadElementRefs
  end
end

class HttpsVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    http = Net::HTTP.new(url.host, url.port)
    req = Net::HTTP::Get.new(url.path)
    http.use_ssl = true
    response = http.request(req)
    open(@name, "wb") { |file|
      file.write(response.body)
    }

    @xml = Nokogiri::XML(File.open(@name)) do |config|
#      config.options = Nokogiri::XML::ParseOptions.STRICT | Nokogiri::XML::ParseOptions.NOENT
      config.strict.noent
      config.strict
    end
  
    File.unlink(@name)   
    loadElementRefs
  end


end

class FtpVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    ftp = Net::FTP.new(url.host, "anonymous", "cops-bot@mitre.org")
      ftp.passive = true
      ftp.getbinaryfile(url.path, @name, 1024)
    ftp.quit()

    @xml = Nokogiri::XML(File.open(@name)) do |config|
      config.strict.noent
      config.strict
    end
  
    File.unlink(@name)   
    loadElementRefs
  end 
end

class FileVmPackage < VmPackage
  def  fetch
    @xml = Nokogiri::XML(File.open(self.url)) do |config|
      config.noblanks.strict.noent
    end
    loadElementRefs
  end
end

class NewVmPackage < VmPackage
  def initialize
  end
end

class Esx4VmPackage < VmPackage
end

class Vc4VmPackage < VmPackage
end
