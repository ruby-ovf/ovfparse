require 'nokogiri'
require 'open-uri'

class VmCollection 
   @url
   @base_path
   @name
   @version
   @protocol
   @size 
   @xml 
   @package_details
   @ovf_namespace
   @default_namespace


   attr_accessor :url, :base_path, :name, :version, :state, :protocol, :size, :xml, :references, :diskSection, :networkSection, :virtualSystemCollection, :package_details

   def initialize
      @package_details = Array.new
   end

   def to_s 
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
      @package_details = Array.new
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
      #if @protocol=='ftp'
      #   FtpVmPackage.new(uri)
      if @protocol=='http'
         HttpVmCollection.new(uri)
      #elsif @protocol=='https'
      #   HttpsVmPackage.new(uri)
      elsif @protocol=='file'
         FileVmCollection.new(uri)
      end
   end


   def fetch
   end 

   # Caches all of the base elements inside Envelope for fast access
   def loadElementRefs
      children = @xml.root.children
      @ovf_namespace = xml.root.namespace_definitions.detect{|ns| ns.prefix == "ovf"}
      @default_namespace = xml.root.namespace

      @references = getChildByName(xml.root, 'References')
      @virtualSystemCollection = getChildByName(xml.root, 'VirtualSystemCollection')

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

   def checkschema(schema)
      response = ""

      isValid = true    
      schema.validate(@xml).each do |error|
         response << error.message + "\n"
         isValid = false
      end

      return [isValid, response]
   end

   def getCollectionName
      return virtualSystemCollection['id'] || ''
   end

   def getCollectionDescription
      descNode = getChildByName(virtualSystemCollection, 'Info')
      return descNode.nil? ? '' : descNode.content
   end

   def setCollectionName(newValue)
      virtualSystem['ovf:id'] = newValue
      nameNode = getChildByName(virtualSystemCollection, 'Name') ||
         getChildByName(virtualSystemCollection, 'Info').add_next_sibling(xml.create_element('Name', {}))
      nameNode.content = newValue
   end

   def setCollectionDescription(newValue)
      getChildByName(virtualSystemCollection, 'Info').content = newValue
   end

   def self.constructFromVmPackages(packages)
      packages.each{ |package|
         addVmPackage(package)
      }
   end

   def addVmPackage(package)
      details = PackageDetails.new()
      details.id = package.getVmName

      newRefs = package.getVmReferences
      newRefs.each { |newRef|
         addFileReference(newRef, package, details)
      }

      newDisks = package.getVmDisks
      newDisks.each { |newDisk|
         addDisk(newDisk, package, details)
      }

      newNetworks = package.getVmNetworks
      newNetworks.each { |newNetwork|
         addNetwork(newNetwork, package, details)
      }
      
      package_details.push(details)
      addVirtualSystem(package.virtualSystem)
   end

   def addFileReference(pendingRef, childPackage, details)
      # Compare this one to all the existing ones to prevent duplicates
      isNewRef = true
      currentFileRefs = getChildrenByName(references, 'File')
      currentFileRefs.each{ |oldRef|
         if(compareFileReferences(oldRef, pendingRef))
            isNewRef = false
            break
         end
      }

      # If it's not a dup, add it
      if(isNewRef)
         newFileID = "file" + (currentFileRefs.length + 1).to_s
         newFile = references.add_child(xml.create_element('File', {'href' => pendingRef['href'], 'id' => newFileID, 'size' => pendingRef['size']}))
         newFile.attribute("href").namespace = @ovf_namespace
         newFile.attribute("id").namespace = @ovf_namespace
         newFile.attribute("size").namespace = @ovf_namespace
         findReplace(childPackage, pendingRef['id'], newFileID)
         details.files.push(newFileID)
      else
         details.files.push(pendingRef['href'])
      end
   end

   def compareFileReferences(oldRef, newRef)
      return (oldRef['href'] == newRef['href']) #&& (oldRef['size'] == newRef['size'])
   end

   def addDisk(newDisk, childPackage, details)
      # Always add a disk, even if it's a clone, cause this VM will need its own copy
      isNewDisk = true
      currentDisks = getChildrenByName(diskSection, 'Disk')
      #currentDisks.each{ |oldDisk|
      #   if(compareDisks(oldDisk, newDisk))
      #      isNewDisk = false
      #      break
      #   end
      #}

      if(isNewDisk)
         newDiskID = "vmdisk" + (currentDisks.length + 1).to_s
         newDiskNode = diskSection.add_child(xml.create_element('Disk', {
            'capacity' => newDisk['size'],
            'diskId' => newDiskID,
            'fileRef' => getChildrenByName(references, 'File').detect{ |ref| ref['href'] == newDisk['location'] }['id'],
            'format' => "http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized",
            'populatedSize' => newDisk['thin_size']
         }))
         newDiskNode.attribute("capacity").namespace = @ovf_namespace
         newDiskNode.attribute("diskId").namespace = @ovf_namespace
         newDiskNode.attribute("fileRef").namespace = @ovf_namespace
         newDiskNode.attribute("format").namespace = @ovf_namespace
         newDiskNode.attribute("populatedSize").namespace = @ovf_namespace
         findReplace(childPackage, newDisk['name'], newDiskID)
         details.disks.push(newDiskID)
      end
   end

   def compareDisks(oldDisk, newDisk)
      filename = getChildrenByName(references, 'File').detect{ |ref| ref['id'] == oldDisk['fileRef'] }['href']
      return (filename == newDisk['location'])
   end

   def addNetwork(newNetwork, childPackage, details)
      isNewNetwork = true
      currentNetworks = getChildrenByName(networkSection, 'Network')
      currentNetworks.each{ |oldNetwork|
         if(compareNetworks(oldNetwork, newNetwork))
            isNewNetwork = false
            break
         end
      }

      if(isNewNetwork)
         newNode = networkSection.add_child(xml.create_element('Network', {'name' => newNetwork['location']}))
         newNode.attribute("name").namespace = @ovf_namespace
         newNode.add_child(xml.create_element('Description', newNetwork['notes']))
      end
      details.networks.push(newNetwork['location'])
   end

   def compareNetworks(oldNetwork, newNetwork)
      return (oldNetwork['name'] == newNetwork['location'])
   end

   def addVirtualSystem(newSystem)
      ovfNamespace = xml.root.namespace
      newNode = virtualSystemCollection.add_child(newSystem.clone)
      newNode.namespace = ovfNamespace
   end

   def findReplace(package, oldval, newval)
      package.xml.xpath("//*").each{ |node|
         if(node.children.length == 1 && node.children[0].text? && node.content.match(oldval) != nil)
            node.content = node.content.gsub(oldval, newval)
         end
         node.attributes.each{ |key, attr|
            attr.value = attr.value.gsub(oldval, newval)
         }
      }
   end

   def search(virtualSystem, value)
      virtualSystem.xpath(".//*").each{ |node|
         if(node.children.length == 1 && node.children[0].text? && node.content.match(value) != nil)
            return true
         end
         node.attributes.each{ |key, attr|
            if(attr.value.match(value) != nil)
               return true
            end
         }
      }
      return false
   end

    # @todo any need to make this a general purpose "writer" ?
   def self.constructSkeleton
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
         xml.Envelope('xmlns' => 'http://schemas.dmtf.org/ovf/envelope/1', 'xmlns:cim' => "http://schemas.dmtf.org/wbem/wscim/1/common", 'xmlns:ovf' => "http://schemas.dmtf.org/ovf/envelope/1", 'xmlns:rasd' => "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData", 'xmlns:vmw' => "http://www.vmware.com/schema/ovf", 'xmlns:vssd' => "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData", 'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 'xmlns:cops' => 'http://cops.mitre.org/1.2', 'xmlns:cpe' => 'http://cpe.mitre.org/dictionary/2.0') {
            xml.References{}
            xml.DiskSection{
               xml.Info "Virtual disk information"
            }
            xml.NetworkSection{
               xml.Info "List of logical networks"
            }
            xml.VirtualSystemCollection('id' => "vm_collection"){
               xml.Info "A collection of virtual machines"
            }
         }

         node = Nokogiri::XML::Comment.new(xml.doc, ' skeleton framework constructed by OVFparse ')
         xml.doc.children[0].add_previous_sibling(node)
      end

      builder.doc.root.children[3].attribute("id").namespace = builder.doc.root.namespace_definitions.detect{ |ns| ns.prefix == "ovf"}
      newPackage = NewVmCollection.new
      newPackage.xml = builder.doc
      newPackage.loadElementRefs
      return newPackage
   end

   def writeXML(filename)
      file = File.new(filename, "w")
      file.puts(xml.to_s)
      file.close
   end

   def splitIntoPackages
      packages = Array.new

      i = 0
      virtualSystems = getChildrenByName(virtualSystemCollection, "VirtualSystem")
      virtualSystems.each{ |virtualSystem|
         details = package_details[i]
         new_package = VmPackage.construct_skeleton
         new_package.loadElementRefs

         details.files.each{ |file|
            node = getChildrenByName(references, "File").detect{ |node| node['id'] == file }
            new_package.references.add_child(node.clone)
         }
            
         details.disks.each{ |disk|
            node = getChildrenByName(diskSection, "Disk").detect{ |node| node['diskId'] == disk }
            new_package.diskSection.add_child(node.clone)
         }

         details.networks.each{ |network|
            node = getChildrenByName(networkSection, "Network").detect{ |node| node['name'] == network }
            new_package.networkSection.add_child(node.clone)
         }

         new_package.virtualSystem.children.unlink
         new_package.virtualSystem['ovf:id'] = virtualSystem['id']
         new_package.virtualSystem.add_child(virtualSystem.clone.children)
         new_package.virtualSystem.children.each{ |child|
            child.namespace = new_package.virtualSystem.namespace
         }
         packages.push(new_package)

         i += 1
      }

      return packages
   end

   def parseXML
      fileRefs = Hash.new
      fileNames = Array.new
      getChildrenByName(references, "File").each{ |fileRef|
         fileNames.push(fileRef['id'])
      }

      diskNames = Array.new
      getChildrenByName(diskSection, "Disk").each{ |disk|
         diskNames.push(disk['diskId'])
         fileRefs[disk['diskId']] = disk['fileRef']
      }

      networkNames = Array.new
      getChildrenByName(networkSection, "Network").each{ |network|
         networkNames.push(network['name'])
      } 

      getChildrenByName(virtualSystemCollection, "VirtualSystem").each{ |virtualSystem|
         details = PackageDetails.new()
         details.id = virtualSystem['id']

         fileNames.each{ |fileName|
            if(search(virtualSystem, fileName))
               details.files.push(fileName)
            end
         }

         diskNames.each{ |diskName|
            if(search(virtualSystem, diskName))
               details.disks.push(diskName)
               if(!details.files.include?(fileRefs[diskName]))
                  details.files.push(fileRefs[diskName])
               end
            end
         }

         networkNames.each{ |networkName|
            if(search(virtualSystem, networkName))
               details.networks.push(networkName)
            end
         }

         package_details.push(details)
      }
   end

end

class NewVmCollection < VmCollection
   def initialize
      @package_details = Array.new
   end
end

class HttpVmCollection < VmCollection
   def fetch 
      url = URI.parse(URI.escape(self.uri))
      @xml = Nokogiri::XML(open(url)) do |config|
         config.noblanks.strict.noent
      end

      loadElementRefs
      parseXML
   end
end

class FileVmCollection < VmCollection
   def fetch
      @xml = Nokogiri::XML(File.open(self.url)) do |config|
         config.noblanks.strict.noent
      end

      loadElementRefs
      parseXML
   end
end

class PackageDetails

   attr_accessor :id, :files, :disks, :networks
   
   def initialize
      @id = ""
      @files = Array.new
      @disks = Array.new
      @networks = Array.new
   end

end