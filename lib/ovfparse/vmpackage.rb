class VmPackage 
  @url
  @name
  @version
  @protocol
  @size 
  @xml 
  

  OVA = 0
  OVF = 1
  ISO = 2
  
  @type = nil
 
  UNKNOWN = 0
  INSTALLED = 1
  NOT_INSTALLED = 2
  UNINSTALLED = 3
  COPYING = 4
  BOOTING = 5
  CONFIGURING = 6 

  # List of attributes in an OVF product that we will extract / set
  PRODUCT_ATTRIBUTES = [ {'full_name' => 'ovf:instance', 'node_ref' => 'instance', 'attribute_ref' => 'instance'},
                         {'full_name' => 'ovf:class', 'node_ref' => 'class', 'attribute_ref' => 'product_class'} ]

  # List of elements in an OVF product that we will extract / set
  PRODUCT_ELEMENTS = [ {'full_name' => 'ovf:Info', 'node_ref' => 'Info', 'element_ref' => 'description', 'required' => false},
                       {'full_name' => 'ovf:Product', 'node_ref' => 'Product', 'element_ref' => 'name', 'required' => false},
                       {'full_name' => 'ovf:Vendor', 'node_ref' => 'Vendor', 'element_ref' => 'vendor', 'required' => false},
                       {'full_name' => 'ovf:Version', 'node_ref' => 'Version', 'element_ref' => 'version', 'required' => false} ]

  # List of attributes in an OVF property that we will extract / set
  PROPERTY_ATTRIBUTES = [ {'full_name' => 'ovf:value', 'node_ref' => 'value', 'attribute_ref' => 'value'},
                          {'full_name' => 'ovf:key', 'node_ref' => 'key', 'attribute_ref' => 'key'},
                          {'full_name' => 'ovf:userConfigurable', 'node_ref' => 'userConfigurable', 'attribute_ref' => 'userConfigurable'},
                          {'full_name' => 'ovf:password', 'node_ref' => 'password', 'attribute_ref' => 'password'},
                          {'full_name' => 'ovf:required', 'node_ref' => 'required', 'attribute_ref' => 'required'},
                          {'full_name' => 'ovf:type', 'node_ref' => 'type', 'attribute_ref' => 'value_basetype'},
                          {'full_name' => 'cops:valueType', 'node_ref' => 'valueType', 'attribute_ref' => 'valueType'},
                          {'full_name' => 'cops:uuid', 'node_ref' => 'uuid', 'attribute_ref' => 'uuid'} ]

  # List of elements in an OVF property that we will extract / set
  PROPERTY_ELEMENTS = [ {'full_name' => 'ovf:Label', 'node_ref' => 'Label', 'element_ref' => 'name', 'required' => false},
                        {'full_name' => 'ovf:Description', 'node_ref' => 'Description', 'element_ref' => 'description', 'required' => false},
                        {'full_name' => 'cops:Example', 'node_ref' => 'cops:Example', 'element_ref' => 'example', 'required' => true},
                        {'full_name' => 'cops:NoneType', 'node_ref' => 'cops:NoneType', 'element_ref' => 'nonetype', 'required' => true} ]
  
  OVF_NAMESPACE = {'ovf' => 'http://schemas.dmtf.org/ovf/envelope/1'}

  @state = UNKNOWN

  attr_accessor :url, :name, :version, :state, :protocol, :size, :xml


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
  
  def referenced_file(element) 
    @xml.xpath("//ovf:References/ovf:File[@ovf:id='#{element['fileRef']}']", OVF_NAMESPACE).first
  end
     
  def method_missing(method)
    puts "WARNING: NoSuchMethod Error: " + method.to_s + " ...trying XPath query \n"
  
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
    xsd = Nokogiri::XML::Schema(File.read(schema))
    response = ""

    isValid = true    
    xsd.validate(@xml).each do |error|
      response << error.message + "\n"
      isValid = false
    end

    return [isValid, response]
  end

  def getVmName
    return xml.xpath('ovf:Envelope/ovf:VirtualSystem')[0]['id']
  end

  def getVmDescription
    descNode = xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:Info')[0]
    return descNode.nil? ? '' : descNode.content
  end

  def getVmOS_ID
    return xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:OperatingSystemSection')[0]['id']
  end

  def getVmPatchLevel
    patchNode = xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:OperatingSystemSection/ovf:Description')[0]
    return patchNode.nil? ? '' : patchNode.text
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
    xml.xpath('ovf:Envelope/ovf:References/ovf:File').each { |node|
      filenames[node['id']] = node['href']
    }

    xml.xpath('ovf:Envelope/ovf:DiskSection/ovf:Disk').each { |node|
      disks.push({ 'name' => node['diskId'], 'location' => filenames[node['fileRef']], 'size' => node['capacity'] })
    }

    return disks
  end

  def getVmNetworks
    networks = Array.new
    xml.xpath('ovf:Envelope/ovf:NetworkSection/ovf:Network').each { |node|
      descriptionNode = node.xpath('ovf:Description')[0]
      text = descriptionNode.nil? ? '' : descriptionNode.text
      networks.push({'location' => node['name'], 'notes' => text })
    }
    return networks
  end

  # What a long strange trip it's been.
  def getVmProducts
    products = Array.new
    xml.root.add_namespace('cops', 'http://cops.mitre.org/1.1')
    xml.root.add_namespace('cpe', 'http://cpe.mitre.org/dictionary/2.0')

    xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:ProductSection').each { |productNode|
       product = Hash.new

       PRODUCT_ATTRIBUTES.each { |attribute_details|
          product[attribute_details['attribute_ref']] = productNode[attribute_details['node_ref']]
       }

       PRODUCT_ELEMENTS.each { |element_details|
          childNode = productNode.xpath(element_details['full_name'])[0]
          product[element_details['element_ref']] = childNode.nil? ? '' : childNode.content
       }

       childNode = productNode.xpath('ovf:Icon')[0]
       begin
       product['icon'] = childNode.nil? ? '' :
          (xml.xpath('ovf:Envelope/ovf:References/ovf:File').detect { |file| file['id'] == childNode['fileRef'] })['href']
       rescue
          puts "You have an icon reference to a file that doesn't exist in the References section."
          return ''
       end
       
       properties = Array.new
       productNode.xpath('ovf:Property').each { |propertyNode|
          property = Hash.new
          PROPERTY_ATTRIBUTES.each { |attribute_details|
             property[attribute_details['attribute_ref']] = propertyNode[attribute_details['node_ref']]
          }

          PROPERTY_ELEMENTS.each { |element_details|
             childNode = propertyNode.xpath(element_details['full_name'])[0]
             property[element_details['element_ref']] = childNode.nil? ? '' : childNode.content
          }

          valueOptionsArray = Array.new
          
          node = propertyNode.xpath('cops:ValueOptions')[0]
          if(!node.nil?)
             if (!node['selection'].nil?)
                property['selection'] = node['selection']
             end
             node.xpath('cops:Option').each { |valueOption|
                valueOptionsArray.push(valueOption.content)
             }
          end

          default = propertyNode['value']
          existingDefault = valueOptionsArray.detect { |option| option == default }
          if (!default.nil? && default != '' && existingDefault.nil?)
             valueOptionsArray.insert(0, default)
          end

          property['valueoptions'] = valueOptionsArray.join("\n")

          actions = Array.new
          node = propertyNode.xpath('cops:Action')[0]
          if(!node.nil?)
             node.xpath('cops:FindReplace').each { |findReplace|
                actions.push({'action_type' => 'FindReplace', 'path' => findReplace.xpath('cops:Path')[0].content, 'value' => findReplace.xpath('cops:Token')[0].content})
             }
             node.xpath('cops:Insert').each { |insert|
                lineNumberNode = insert.xpath('cops:LineNumber')[0]
                lineNumber = lineNumberNode.nil? ? '' : lineNumberNode.content
                actions.push({'action_type' => 'Insert', 'path' => insert.xpath('cops:Path')[0].content, 'value' => lineNumber})
             }
             node.xpath('cops:Registry').each { |registry|
                actions.push({'action_type' => 'Registry', 'path' => registry.xpath('cops:RegistryPath')[0].content, 'value' => ''})
             }
             node.xpath('cops:Execute').each { |execute|
                optionsNode = execute.xpath('cops:Options')[0]
                options = optionsNode.nil? ? '' : optionsNode.content
                actions.push({'action_type' => 'Execute', 'path' => execute.xpath('cops:Path')[0].content, 'value' => options})
             }

          end
          
          container = [property, actions]
          properties.push(container)
       }
       
       container = [product, properties]
       products.push(container)
    }
    return products
  end

  def getVmCPUs
    return getVirtualQuantity(3)
  end

  def getVmRAM
    return getVirtualQuantity(4)
  end

  def getVirtualQuantity(resource)
    xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item').each { |node|
      resourceType = node.xpath('rasd:ResourceType')[0].text
      resourceType == resource.to_s ? (return node.xpath('rasd:VirtualQuantity')[0].text) : next
    }
  end

  def setVmName(newValue)
    xml.xpath('ovf:Envelope/ovf:VirtualSystem')[0]['ovf:id'] = newValue
    nameNode = xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:Name')[0] ||
       xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:Info')[0].add_next_sibling(xml.create_element('Name', {}))
    nameNode.content = newValue
  end

  def setVmDescription(newValue)
    xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:Info')[0].content = newValue
  end

  def setVmOS_ID(newValue)
    xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:OperatingSystemSection')[0]['ovf:id'] = newValue.to_s
  end

  def setVmPatchLevel(newValue)
    osNode = xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:OperatingSystemSection')[0]
    descNode = osNode.xpath('ovf:Description')[0] || osNode.add_child(xml.create_element('Description', {}))
    descNode.content = newValue
  end

  def setVmCPUs(newValue)
    setVirtualQuantity(3, newValue)
  end

  def setVmRAM(newValue)
    setVirtualQuantity(4, newValue)
  end

  def setVirtualQuantity(resource, newValue)
    xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item').each { |node|
      resourceType = node.xpath('rasd:ResourceType')[0].text
      resourceType == resource.to_s ? (node.xpath('rasd:VirtualQuantity')[0].content = newValue) : next
    }
  end

  def setVmNetworks(networks)
     networkSection = xml.xpath('ovf:Envelope/ovf:NetworkSection')[0]
     networkNodes = networkSection.xpath('ovf:Network')
    
     networkNodes.each { |node|
        updated_network = networks.detect { |network| network.location == node['name'] }
        if(updated_network.nil?)
           node.unlink
        else
           descriptionNode = node.xpath('ovf:Description')[0]
           if((updated_network.notes == '' || updated_network.notes.nil?) && !descriptionNode.nil?)
              descriptionNode.unlink
           elsif(updated_network.notes != '' && !updated_network.notes.nil?)
		descriptionNode = descriptionNode || descriptionNode.add_child(xml.create_element("Description", {}))
              descriptionNode.content = updated_network.notes
           end
        end
     }

     networks.each { |network|
        if( (networkNodes.detect { |node| network.location == node['name'] }).nil?)
           networkNode = networkSection.add_child(xml.create_element('Network', {'ovf:name' => network.location}))
           if(network.notes != '' && !network.notes.nil?)
              networkNode.add_child(xml.create_element('Description', network.notes))
           end
        end
     }
  end

  def setVmDisks(disks)
     fileSection = xml.xpath('ovf:Envelope/ovf:References')[0]
     fileNodes = fileSection.xpath('ovf:File')

     diskSection = xml.xpath('ovf:Envelope/ovf:DiskSection')[0]
     diskNodes = diskSection.xpath('ovf:Disk')

     icons = Array.new
     xml.xpath('ovf:Envelope/ovf:VirtualSystem/ovf:ProductSection/ovf:Icon').each { |node|
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

     disks.each { |disk|
        if( (fileNodes.detect { |node| disk.location == node['href'] }).nil?)
           diskSection.add_child(xml.create_element('Disk', {'ovf:capacity' => disk.size.to_s, 'ovf:capacityAllocationUnits' => "byte * 2^30", 'ovf:diskId' => disk.name, 'ovf:fileRef' => disk.name + '_disk', 'ovf:format' => "http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized" }))
           fileSection.add_child(xml.create_element('File', {'ovf:href' => disk.location, 'ovf:id' => disk.name + '_disk'}))
        end
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
     iconNode = productNode.xpath('ovf:Icon')[0]
     if((new_icon == '' || new_icon.nil?) && !iconNode.nil?)
        (xml.xpath('ovf:Envelope/ovf:References/ovf:File').detect { |fileNode| fileNode['id'] == iconNode['fileRef']}).unlink
        iconNode.unlink
     elsif(new_icon != '' && !new_icon.nil?)
        if(iconNode.nil?)
           productNode.add_child(xml.create_element('Icon', {'ovf:fileRef' => productNode['class'] + '_icon'}))
           xml.xpath('ovf:Envelope/ovf:References')[0].add_child(xml.create_element('File', {'ovf:id' => productNode['class'] + '_icon', 'ovf:href' => new_icon}))
        else
           (xml.xpath('ovf:Envelope/ovf:References/ovf:File').detect { |fileNode| fileNode['id'] == iconNode['fileRef']})['ovf:href'] = new_icon
        end
     end
  end

  def setElements(updated_element, parent_node, element_list)
     element_list.each { |element_details|
        updated_value = updated_element[element_details['element_ref']]
        element_node = parent_node.xpath(element_details['full_name'])[0]
        if((updated_value == '' || updated_value.nil?) && !element_node.nil?)
           element_node.unlink
        elsif(updated_value != '' && !updated_value.nil?)
           element_node = element_node || parent_node.add_child(xml.create_element(element_details['node_ref'], updated_value))
           element_node.content = updated_value
           if(element_details['required'])
              element_node['ovf:required'] = 'false'
           end
        end
     }
  end

  def setAttributes(updated_element, parent_node, attribute_list)
     attribute_list.each { |attribute_details|
        updated_value = updated_element[attribute_details['attribute_ref']]
        (updated_value == '' || updated_value.nil?) ? parent_node.delete(attribute_details['node_ref']) : parent_node[attribute_details['full_name']] = updated_value
     }
  end

  def setVmProducts(products)
    virtualSystem = xml.xpath('ovf:Envelope/ovf:VirtualSystem')[0]
    productNodes = virtualSystem.xpath('ovf:ProductSection')

    # Removing old ones that don't exist anymore, updating ones that do
    productNodes.each { |productNode|
       updated_product = products.detect { |product| productNode['class'] == product.product_class }
       if(updated_product.nil?)
          productNode.unlink
       else
          setAttributes(updated_product, productNode, PRODUCT_ATTRIBUTES)
          setElements(updated_product, productNode, PRODUCT_ELEMENTS)
          setProductIcon(updated_product.icon, productNode)
          setProperties(productNode, updated_product.coat_properties)
       end
    }

    # Adding new products
    products.each { |product|
       if((productNodes.detect { |node| node['class'] == product.product_class }).nil?)
          newProductNode = virtualSystem.add_child(xml.create_element('ProductSection', {}))
          setAttributes(product, newProductNode, PRODUCT_ATTRIBUTES)
          setElements(product, newProductNode, PRODUCT_ELEMENTS)
          setProductIcon(product.icon, newProductNode)
          setProperties(newProductNode, product.coat_properties)
       end
    }
  end

  def setProperties(product, properties)
     propertyNodes = product.xpath('ovf:Property')

     propertyNodes.each { |propertyNode|
       updated_property = properties.detect { |property| propertyNode['key'] == property.key }
       if(updated_property.nil?)
          propertyNode.unlink
       else
          setAttributes(updated_property, propertyNode, PROPERTY_ATTRIBUTES)
          setElements(updated_property, propertyNode, PROPERTY_ELEMENTS)
          setValueOptions(propertyNode, updated_property)
          propertyNode['ovf:type'] = 'string'
          setActions(propertyNode, updated_property.coat_actions)
       end
    }

    properties.each { |property|
       if((propertyNodes.detect { |node| node['key'] == property.key }).nil?)
          newPropertyNode = product.add_child(xml.create_element('Property', {}))
          setAttributes(property, newPropertyNode, PROPERTY_ATTRIBUTES)
          setElements(property, newPropertyNode, PROPERTY_ELEMENTS)
          setValueOptions(newPropertyNode, property)
          newPropertyNode['ovf:type'] = 'string'
          setActions(newPropertyNode, property.coat_actions)
       end
    }
  end

  def setValueOptions(property_node, property)
     values = property.valueoptions.split("\n")
     valueOptionsNode = property_node.xpath('cops:ValueOptions')[0]
     if(values.empty? && !valueOptionsNode.nil?)
        valueOptionsNode.unlink
     elsif(!values.empty?)
        valueOptionsNode = valueOptionsNode || property_node.add_child(xml.create_element('ValueOptions', {}))
        valueOptionsNode.namespace = xml.root.namespace_definitions.detect{ |ns| ns.prefix == 'cops' }
        valueOptionsNode['cops:selection'] = (property.selection || 'single')
        valueOptionsNode['ovf:required'] = 'false'
        valueOptionsNode.children.unlink
        existingDefault = values.detect { |value| value == property.value }
        if(property.value != '' && !property.value.nil? && existingValue.nil?)
           valueOptionsNode.add_child(xml.create_element('Option', property.value))
        end
        values.each { |value|
           valueOptionsNode.add_child(xml.create_element('Option', value))
        }
     end
  end

  def setActions(property, actions)
     actionsNode = property.xpath('cops:Action')[0]
     if(actions.empty? && !actionsNode.nil?)
        actionsNode.unlink
     elsif(!actions.empty?)
        actionsNode = actionsNode || property.add_child(xml.create_element('Action', {}))
        actionsNode.namespace = xml.root.namespace_definitions.detect{ |ns| ns.prefix == 'cops' }
        actionsNode['ovf:required'] = 'false'
        actionsNode.children.unlink
        actions.each { |action|
           newActionNode = actionsNode.add_child(xml.create_element(action.action_type, {}))
           if(action.action_type == 'FindReplace')
              newActionNode.add_child(xml.create_element('Path', action.path))
              newActionNode.add_child(xml.create_element('Token', action.value))
           elsif(action.action_type == 'Insert')
              newActionNode.add_child(xml.create_element('Path', action.path))
              if(action.value != '' && !action.value.nil?)
                 newActionNode.add_child(xml.create_element('LineNumber', action.value))
              end
           elsif(action.action_type == 'Registry')
              newActionNode.add_child(xml.create_element('RegistryPath', action.path))
           elsif(action.action_type == 'Execute')
              newActionNode.add_child(xml.create_element('Path', action.path))
              if(action.value != '' && !action.value.nil?)
                 newActionNode.add_child(xml.create_element('Options', action.value))
              end
           end
        }
     end
  end

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
      node = Nokogiri::XML::Comment.new(xml.doc, ' skeleton framework constructed by COAT ')
      xml.doc.children[0].add_previous_sibling(node)
    end
    return builder.to_xml
  end

  def write_xml(file)
    xml.write_xml_to(file)
  end

  def sign
    node = Nokogiri::XML::Comment.new(xml, ' made with love by the cops ovf authoring tool. ')
    xml.children[0].add_next_sibling(node)
  end

  def xpath(string)
    puts @xml.xpath(string)
  end

end 

class HttpVmPackage < VmPackage
  def fetch 
    url = URI.parse(URI.escape(self.uri))
    Net::HTTP.start(url.host) { |http|
      resp = http.get(url.path)
      open(@name, "wb") { |file|
        file.write(resp.body)
      }
    }

    @xml = Nokogiri::XML(File.open(@name)) do |config|
      config.strict.noent
      config.strict
    end

    File.unlink(@name)   
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
  end 
end

class FileVmPackage < VmPackage
  def  fetch
    @xml = Nokogiri::XML(File.open(self.url)) do |config|
      config.noblanks.strict.noent
    end
  end
end

class Esx4VmPackage < VmPackage
end

class Vc4VmPackage < VmPackage
end
