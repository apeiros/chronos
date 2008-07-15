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
		
		def normalize_language(val)
			raise ArgumentError, "Invalid language #{val.inspect}" unless lang = val[/^[a-z]{2}_[A-Z]{2}/]
		end
		
		def normalize_timezone(val)
			val.upcase
		end
		
		def language=(value)
			@language = normalize_language(value).dup.freeze
		end

		def timezone=(value)
			@language = normalize_language(value).dup.freeze
		end
	end

	self.language = ENV['LANG'] || 'en_US'
	self.timezone = Time.now.strftime("%Z")
end
