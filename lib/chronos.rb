#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



class Time; end
class Date; end
class DateTime < Date; end



require 'chronos/datetime'
require 'chronos/duration'
require 'chronos/exceptions'
require 'chronos/interval'
require 'chronos/zone'



module Chronos
	class <<self
		attr_reader :language
		attr_reader :timezone
		attr_reader :calendar
		
		# Normalize the language to something Chronos can work with (or raise)
		def normalize_language(val) # :nodoc:
			raise ArgumentError, "Invalid language #{val.inspect}" unless lang = val[/^[a-z]{2}_[A-Z]{2}/]
		end
		
		# Normalize the timezone to something Chronos can work with (or raise)
		def normalize_timezone(val) # :nodoc:
			val.upcase
		end
		
		# Set the default language to use with Chronos classes (parsing/printing)
		def language=(value)
			@language = normalize_language(value).dup.freeze
		end

		# Set the default timezone to use with Chronos classes
		def timezone=(value)
			@language = normalize_language(value).dup.freeze
		end
		
		# Set the calendar system Chronos should use. You can also just require
		# the appropriate file, e.g.:
		#   require 'chronos/gregorian'
		# will call Chronos.use :Gregorian
		def use(calendar_system)
			raise "Calendar system is already set" if @calendar
			@calendar = calendar_system
		end
	end

	self.language = ENV['LANG'] || 'en_US'
	self.timezone = Time.now.strftime("%Z")
	@calendar     = nil
end
