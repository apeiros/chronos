#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :git do
	if Project.meta.use_git then
		# A prerequisites task that all other tasks depend upon
		task :prereqs
	
		desc 'Show tags from the Git repository'
		task :tags => 'git:prereqs' do |t|
			system 'git', 'tag'
		end
	
		desc 'Create a new tag in the Git repository'
		task :create_tag => 'git:prereqs' do |t|
			v = ENV['VERSION'] or abort 'Must supply VERSION=x.y.z'
	
			tag = "%s-%s" % [Project.meta.name, Project.meta.version]
			msg = "Creating tag for #{Project.meta.name} version #{Project.meta.version}"
	
			puts "Creating Git tag '#{tag}'"
			unless system "git tag -a -m '#{msg}' #{tag}"
				abort "Tag creation failed"
			end
	
			if %x/git remote/ =~ %r/^origin\s*$/
				unless system "git push origin #{tag}"
					abort "Could not push tag to remote Git repository"
				end
			end
		end
	end
end  # namespace :git

task 'gem:release' => 'git:create_tag' if Project.meta.use_git
