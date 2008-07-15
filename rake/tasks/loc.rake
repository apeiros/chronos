#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :loc do
	desc 'Assess the number of code and comment lines'
	task :assess do
		next unless lib?('assesscode', 'Requires AssessCode lib to count lines of code and comment.')
		a = AssessCode.new(
			'.',
			'lib/**/*.rb',
			'bin/**/*',
			'data/**/*.rb'
		)
		puts "Code"
		a.put_assessment

		a = AssessCode.new(
			'.',
			'spec/**/*.rb',
			'test/**/*.rb'
		)
		puts "\nTests"
		a.put_assessment
	end
end  # namespace :loc

desc 'Alias to loc:assess'
task :loc => 'loc:assess'
