#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :copyright do
	task :update do
		manifest().each { |file|
			data = File.read(file).gsub(/(copyright \d+)(?:(\s*-\s*)\d+)?( by)/i) {
				copyright = "#{$1}#{$2 || '-'}#{Time.now.year}#{$3}"
				puts "#{file}: replacing #{$&.inspect} with #{copyright.inspect}"
				copyright
			}
			File.open(file, "wb") { |fh| fh.write(data) }
		}
	end
end  # namespace :copyright

desc 'Alias to copyright:update'
task :copyright => 'copyright:update'

