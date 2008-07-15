#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :manifest do
	# prerequisite task finalizes Project.manifest
	task :prerequisite => 'meta:prerequisite' do
		abort("No instructions for manifest tasks in Project") unless Project.manifest

		Project.manifest.file ||= Project.meta.manifest
		Project.manifest.__finalize__
	end

	desc 'Verify the manifest'
	task :check => :prerequisite do
		files   = manifest()
		cands   = manifest_candidates()
		missing = files-cands
		added   = cands-files

		puts "#{Project.manifest.file.inspect}:"
		puts added.sort.map { |f|
			"\e[32m+#{f}\e[0m"
		}
		puts missing.sort.map { |f|
			"\e[31m-#{f}\e[0m"
		}
		puts "Manifest is up to date." if missing.empty? and added.empty?
	end

	desc 'Create a new manifest'
	task :create => :prerequisite do
		abort("No manifest file path given in Project.manifest.file") unless Project.manifest.file

		unless File.exist?(Project.manifest.file) then
			files = manifest_candidates()+[Project.manifest.file]
			files.sort!
			File.open(Project.manifest.file, 'wb') {|fp| fp.puts files}
			puts "#{Project.manifest.file.inspect} Created."
		else
			abort("#{Project.manifest.file.inspect} exists already.")
		end
	end

	task :assert => :prerequisite do
		files   = manifest()
		cands   = manifest_candidates()
		missing = files-cands
		added   = cands-files

		unless (missing.empty? and added.empty?)
			raise "ERROR: #{Project.manifest.file.inspect} is out of date"
		end
	end

end  # namespace :manifest

desc 'Alias to manifest:check'
task :manifest => 'manifest:check'
