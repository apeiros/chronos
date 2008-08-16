#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos/duration/gregorian'



module Chronos
	module Numeric
		module Gregorian
			def picoseconds(language)
				::Chronos::Duration::Gregorian.new(self, 0, language)
			end
			alias picosecond picoseconds

			def nanoseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_NANOSECOND, 0, language)
			end
			alias nanosecond nanoseconds

			def microseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MICROSECOND, 0, language)
			end
			alias microsecond microseconds

			def milliseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MILLISECOND, 0, language)
			end
			alias millisecond milliseconds

			def seconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_SECOND, 0, language)
			end
			alias second seconds

			def minutes(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MINUTE, 0, language)
			end
			alias minute minutes

			def hours(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_HOUR, 0, language)
			end
			alias hour hours

			def days(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_DAY, 0, language)
			end
			alias day days

			def weeks(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_WEEK, 0, language)
			end
			alias week weeks

			def months(language)
				::Chronos::Duration::Gregorian.new(0, self, language)
			end
			alias month months

			def years(language)
				::Chronos::Duration::Gregorian.new(0, self*12, language)
			end
			alias year years
		end
	end
end

class Numeric
	include Chronos::Numeric::Gregorian
end
