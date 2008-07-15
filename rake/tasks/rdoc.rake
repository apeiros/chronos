#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'rake/rdoctask'



namespace :doc do
	if Project.rdoc.nil? then
		task :missing_project do
			abort("No instructions in Project to run the gem tasks")
		end

		task :rdoc         => :missing_project
		task :clobber_rdoc => :missing_project
		task :coverage     => :missing_project
		task :ri           => :missing_project
		task :clobber_ri   => :missing_project
	elsif !lib?('rake/rdoctask') then
		task :missing_rdoctask do
			abort("Missing rake/rdoctask in Project to run the gem tasks")
		end

		task :rdoc         => :missing_rdoctask
		task :clobber_rdoc => :missing_rdoctask
		task :coverage     => :missing_rdoctask
		task :ri           => :missing_rdoctask
		task :clobber_ri   => :missing_rdoctask
	else
		# defaultize rdoc task
		Project.rdoc.files   ||= []
		Project.rdoc.files    += FileList.new(Project.rdoc.include || %w[lib/**/* *.{txt markdown rdoc}])
		Project.rdoc.files    -= FileList.new(Project.rdoc.exclude) if Project.rdoc.exclude
		Project.rdoc.files.reject! { |f| File.directory?(f) }
		Project.rdoc.title   ||= "#{Project.meta.name}-#{Project.meta.version} Documentation"
		Project.rdoc.options ||= []
		Project.rdoc.options.push('-t', Project.rdoc.title)
		Project.rdoc.main    ||= Project.meta.readme
		Project.rdoc.__finalize__

		Rake::RDocTask.new do |rd|
			rd.main       = Project.rdoc.main
			rd.rdoc_files = Project.rdoc.files
			rd.rdoc_dir   = Project.rdoc.output_dir
			rd.template   = Project.rdoc.template if Project.rdoc.template
			
			rd.options.concat(Project.rdoc.options)
		end
	
		desc 'Check documentation coverage with dcov'
		task :coverage do
			sh "find lib -name '*.rb' | xargs dcov"
		end
	
		desc 'Generate ri locally for testing'
		task :ri => :clobber_ri do
			sh "#{RDOC} --ri -o ri ."
		end
	
		desc 'Remove ri products'
		task :clobber_ri do
			rm_r 'ri' rescue nil
		end
	end
end

desc 'Alias to doc:rdoc'
task :doc => 'doc:rdoc'
