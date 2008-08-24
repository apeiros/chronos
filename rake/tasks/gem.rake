#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :gem do

	# No data in Project
	if Project.gem.nil? then
		task :missing_project do
			abort("No instructions in Project to run the gem tasks")
		end
		
		task :package   => :missing_project
		task :info      => :missing_project
		task :install   => :missing_project
		task :uninstall => :missing_project
		task :cleanup   => :missing_project
		task :clobber

	# Rubygems is not installed
	elsif !lib?('rubygems') then
		task :missing_rubygems do
			abort("Requires rubygems to run")
		end
		
		task :package   => :missing_rubygems
		task :info      => :missing_rubygems
		task :install   => :missing_rubygems
		task :uninstall => :missing_rubygems
		task :cleanup   => :missing_rubygems
		task :clobber

	# Prerequisites met
	else
		Project.gem.name                  ||= Project.meta.name
		Project.gem.version               ||= Project.meta.version
		Project.gem.summary               ||= Project.meta.summary
		Project.gem.description           ||= Project.meta.description
		Project.gem.authors               ||= Project.meta.authors || Array(Project.meta.author)
		Project.gem.email                 ||= Project.meta.email
		Project.gem.homepage              ||= Project.meta.website
		Project.gem.rubyforge_project     ||= (Project.rubyforge && Project.rubyforge.name) || Project.meta.name
		Project.gem.files                 ||= manifest()
		Project.gem.executables           ||= Array(Project.gem.executable)
		Project.gem.extensions            ||= Project.gem.files.grep %r/extconf\.rb$/
		Project.gem.bin_dir               ||= "bin"
	
		Project.gem.rdoc_options          ||= Project.rdoc && Project.rdoc.options
		Project.gem.extra_rdoc_files      ||= Project.rdoc && Project.rdoc.extra_files
		Project.gem.rdoc_options          ||= Project.rdoc && Project.rdoc.options
		Project.gem.__finalize__
		Project.gem.spec = gem_spec(Project.gem)

		# task gem:package
		dependency 'rake/gempackagetask', 'Requires rake/gempackagetask'
		pkg = Rake::GemPackageTask.new(Project.gem.spec) do |pkg|
			pkg.need_tar      = Project.gem.need_tar
			pkg.need_zip      = Project.gem.need_zip
			pkg.package_files = Project.gem.files if Project.gem.files
		end
		# Rake::Task['gem:package'].instance_variable_set(:@full_comment, nil)
	
		Project.gem.gem_file ||= gem_file(Project.gem.spec, pkg.package_name)
	
		desc 'Show information about the gem'
		task :info do
			puts "package_files:"
			puts Project.gem.files
			puts Project.gem.spec.to_ruby
		end
	
		desc "Build the gem file #{Project.gem.gem_file}"
		task :package => %W[#{pkg.package_dir}/#{Project.gem.gem_file}]
	
		file "#{pkg.package_dir}/#{Project.gem.gem_file}" => [pkg.package_dir, *Project.gem.files] do
			when_writing("Creating GEM") {
				Gem::Builder.new(Project.gem.spec).build
				verbose(true) {
					mv Project.gem.gem_file, "#{pkg.package_dir}/#{Project.gem.gem_file}"
				}
			}
		end
	
		desc 'Install the gem'
		task :install => [:clobber, 'gem:package'] do
			sh "#{bin.sudo unless File.writable?(Gem.dir)} #{bin.gem} install --no-update-sources pkg/#{Project.gem.spec.full_name}"
		end
	
		desc 'Reinstall the gem'
		task :reinstall => [:uninstall, :install]
	
		desc 'Uninstall the gem'
		task :uninstall do
			if installed_list = Gem.source_index.find_name(Project.gem.name) then
				installed_versions = installed_list.map { |s| s.version.to_s }
				if installed_versions.include?(Project.gem.version) then
					sh "#{bin.sudo unless File.writable?(Gem.dir)} #{bin.gem} uninstall --version '#{Project.gem.version}' --ignore-dependencies --executables #{Project.gem.name}"
				end
			end
		end
	
		desc 'Cleanup the gem'
		task :cleanup do
			abort("Gem name not set in Project.gem") unless Project.gem.name
			sh "#{bin.sudo unless File.writable?(Gem.dir)} #{bin.gem} cleanup #{Project.gem.name}"
		end

		task :clobber => :clobber_package
	end
end  # namespace :gem

desc 'Alias to gem:package'
task :gem     => 'gem:package'
task :clobber => 'gem:clobber'

