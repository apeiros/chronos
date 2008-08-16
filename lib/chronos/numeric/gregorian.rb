#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos/duration/gregorian'



module Chronos
	module Numeric
		module Gregorian

			# Get a duration of the receivers amount of picoseconds
			def picoseconds(language)
				::Chronos::Duration::Gregorian.new(self, 0, language)
			end
			alias picosecond picoseconds

			# Get a duration of the receivers amount of nanoseconds
			def nanoseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_NANOSECOND, 0, language)
			end
			alias nanosecond nanoseconds

			# Get a duration of the receivers amount of microseconds
			def microseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MICROSECOND, 0, language)
			end
			alias microsecond microseconds

			# Get a duration of the receivers amount of milliseconds
			def milliseconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MILLISECOND, 0, language)
			end
			alias millisecond milliseconds

			# Get a duration of the receivers amount of seconds
			def seconds(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_SECOND, 0, language)
			end
			alias second seconds

			# Get a duration of the receivers amount of minutes
			def minutes(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_MINUTE, 0, language)
			end
			alias minute minutes

			# Get a duration of the receivers amount of hours
			def hours(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_HOUR, 0, language)
			end
			alias hour hours

			# Get a duration of the receivers amount of days
			def days(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_DAY, 0, language)
			end
			alias day days

			# Get a duration of the receivers amount of weeks
			def weeks(language)
				::Chronos::Duration::Gregorian.new(self*::Chronos::PS_IN_WEEK, 0, language)
			end
			alias week weeks

			# Get a duration of the receivers amount of months
			def months(language)
				::Chronos::Duration::Gregorian.new(0, self, language)
			end
			alias month months

			# Get a duration of the receivers amount of years
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
