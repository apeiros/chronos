#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :notes do
	desc "Show all annotations"
	task :show, :tags do |t, args|
		tags = if args.tags then
			args.tags.split(/,\s*/)
		else
			Project.notes.tags
		end
		regex = /^.*(?:#{tags.map { |e| Regexp.escape(e) }.join('|')}).*$/
		puts "Searching for tags #{tags.join(', ')}"
		Project.notes.include.each { |glob|
			Dir.glob(glob) { |file|
				data   = File.read(file)
				header = false
				data.scan(regex) {
					unless header then
						puts "#{file}:"
						header = true
					end
					printf "- %4d: %s\n", $`.count("\n")+1, $&.strip
				}
			}
		}
	end
end # namespace :notes

desc "Alias for notes:show. You have to use notes:show directly to use arguments."
task :notes => 'notes:show'
