#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :meta do
	task :prerequisite do
		Project.manifest.__finalize__
	end
end  # namespace :meta

#desc 'Alias to manifest:check'
#task :manifest => 'manifest:check'
