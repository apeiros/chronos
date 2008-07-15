#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



class AssessCode
	def initialize(base, *paths)
		@base          = base
		@paths         = paths
		reset
	end
	
	def reset
		@loc_code      = 0
		@loc_comment   = 0
		@bytes_code    = 0
		@bytes_comment = 0
		@bytes_data    = 0
		@files         = 0
	end
	
	def assess
		reset
		@paths.each { |path|
			assess_dir("#{@base}/#{path}")
		}
	end
	
	def assess_dir(dir)
		Dir.glob(dir, &method(:assess_file))
	end
	
	def assess_file(file)
		comment      = false
		@bytes_data += File.size(file)
		@files      += 1
		File.readlines(file).each do |line|
			comment = true if line =~ /^=begin/
			comment = false if line =~ /^=end/
			if comment or line =~ /^\s*(?:#|$)/
				@loc_comment   += 1
				@bytes_comment += line.strip.size
			else
				@loc_code   += 1
				@bytes_code += line.strip.size
			end
		end
	end
		
	def put_assessment
		assess
		puts "#{@bytes_data.div(1024)} KB total data in #{@files} files"
		puts "#{@loc_code} Lines of Code (#{@bytes_code.div(1024)} KB)"
		puts "#{@loc_comment} Lines of Comment (#{@bytes_comment.div(1024)} KB)"
	end
end # class AssessCode
