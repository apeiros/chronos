#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'
require 'chronos/datetime/gregorian'
require 'chronos/duration/gregorian'
require 'chronos/interval/gregorian'



module Chronos
	class Calendar
		class Gregorian < ::Chronos::Calendar
			class <<self
				def method_missing(*args, &block)
					new(Chronos::Datetime::Gregorian.send(*args, &block))
				end
			end
			
			def initialize(datetime)
				@datetime = datetime
				@language = datetime.language
			end
			
			def year=(value)
				@datetime += Chronos::Duration::Gregorian.new(0, value*12, @language)
			end
			
			def month=(value)
				@datetime += Chronos::Duration::Gregorian.new(0, value, @language)
			end

			def week=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_WEEK, 0, @language)
			end
			
			def day=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_DAY, 0, @language)
			end
			
			def hour=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_HOUR, 0, @language)
			end
			
			def minute=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_MINUTE, 0, @language)
			end
			
			def second=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_SECOND, 0, @language)
			end
			
			def millisecond=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_MILLISECOND, 0, @language)
			end
			
			def microsecond=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_MICROSECOND, 0, @language)
			end
			
			def nanosecond=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_NANOSECOND, 0, @language)
			end
			
			def picosecond=(value)
				@datetime += Chronos::Duration::Gregorian.new(value*Chronos::PS_IN_PICOSECOND, 0, @language)
			end
			
			def method_missing(*args, &block)
				r = @datetime.send(*args, &block)
				if r.class == ::Chronos::Datetime::Gregorian then
					@datetime = r
					self
				else
					r
				end
			end
		end # Gregorian
	end # Calendar
end # Chronos
