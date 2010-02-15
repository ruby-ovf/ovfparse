require 'rake/gempackagetask' 

spec = Gem::Specification.new do |s| 
  s.name = "ovfparse"
  s.version = "0.0.1"
  s.author = "Jim Barkley"
  s.email = "jbarkley@mitre.org"
  s.homepage = ""
  s.platform = Gem::Platform::RUBY
  s.summary = "Retrieves and parses files in the Open Virtualization Format"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
#  s.autorequire = "name"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
#  s.add_dependency("dependency", ">= 0.x.x")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 

