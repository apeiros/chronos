#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# Look in the rake/initialize.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the rake/tasks directory
# are where the options are used.
require 'rake/initialize'

# The default task
task :default => 'spec:run'



# Project details (defaults are in rake/initialize, some cleanup is done per section in the
# prerequisite task in each .task file, some other cleanup is done in post_load.rake)
Project.meta.name             = 'chronos'
Project.meta.version          = version_proc("Chronos::VERSION")
Project.meta.website          = 'http://chronos.rubyforge.org/'
Project.meta.bugtracker       = 'http://'
Project.meta.feature_requests = 'http://'
Project.meta.use_git          = true

Project.manifest.ignore       = %w[web/**/*]

Project.rubyforge.project     = 'chronos'
Project.rubyforge.path        = 'chronos'
