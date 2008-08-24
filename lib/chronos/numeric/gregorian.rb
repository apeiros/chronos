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
				::Chronos::Duration::Gregorian.new(0, 0, self, 0, language)
			end
			alias picosecond picoseconds

			# Get a duration of the receivers amount of nanoseconds
			def nanoseconds(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_NANOSECOND, language)
			end
			alias nanosecond nanoseconds

			# Get a duration of the receivers amount of microseconds
			def microseconds(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_MICROSECOND, language)
			end
			alias microsecond microseconds

			# Get a duration of the receivers amount of milliseconds
			def milliseconds(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_MILLISECOND, language)
			end
			alias millisecond milliseconds

			# Get a duration of the receivers amount of seconds
			def seconds(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_SECOND, language)
			end
			alias second seconds

			# Get a duration of the receivers amount of minutes
			def minutes(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_MINUTE, language)
			end
			alias minute minutes

			# Get a duration of the receivers amount of hours
			def hours(language)
				::Chronos::Duration::Gregorian.new(0, 0, self*::Chronos::PS_IN_HOUR, language)
			end
			alias hour hours

			# Get a duration of the receivers amount of days
			def days(language)
				::Chronos::Duration::Gregorian.new(0, self, 0, language)
			end
			alias day days

			# Get a duration of the receivers amount of weeks
			def weeks(language)
				::Chronos::Duration::Gregorian.new(0, self*7, 0, language)
			end
			alias week weeks

			# Get a duration of the receivers amount of months
			def months(language)
				::Chronos::Duration::Gregorian.new(self, 0, 0, language)
			end
			alias month months

			# Get a duration of the receivers amount of years
			def years(language)
				::Chronos::Duration::Gregorian.new(self*12, 0, 0, language)
			end
			alias year years

			# Get a duration of the receivers amount of decades
			def decades(language)
				::Chronos::Duration::Gregorian.new(self*144, 0, 0, language)
			end
			alias decade decades

			# Get a duration of the receivers amount of centuries
			def centuries(language)
				::Chronos::Duration::Gregorian.new(self*1200, 0, 0, language)
			end
			alias century centuries
		end
	end
end

class Numeric
	include Chronos::Numeric::Gregorian
end
