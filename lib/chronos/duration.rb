#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos

	# An immutable class representing a "floating" (independant of
	# a start or end) period.
	# A Durations months-count becomes determinated by adding it to or
	# subtracting it from a Datetime.
	# Also see Interval
	class Duration
		# if you want to estimate minimum seconds in months
		MinSecondsInMonths = [
			0,
			2419200,
			5097600,
			7689600,
			10368000,
			12960000,
			15638400,
			18316800,
			20908800,
			23587200,
			26179200,
			28857600,
			31536000
		]

		# if you want to estimate maximum seconds in months
		MaxSecondsInMonths = [
			0,       # 0 days
			2678401, # 31 days + leapsecond (june/december)
			5356800, # 62 days (july, august)
			7948801, # 92 days + leapsecond (june, july, august)
			10627201, # 123 days + leapsecond
			13219201,
			15897601,
			18489602,
			21168002,
			23760002,
			26438402,
			29116802,
			31622402,
		]

		def self.with(parts)
			data    = Hash.new(0).merge(parts)
			seconds = data[:seconds]+
			          data[:minutes]*60+
			          data[:hours]*3600+
			          data[:days]*86400+
			          data[:weeks]*604800
			months  = data[:months]+
			          data[:years]*12
			new(seconds, months)
		end
		
		# seconds+months
		def initialize(seconds, months=0)
			@seconds = seconds
			@months  = months
		end

		def +@
			dup
		end
		
		def -@
			Duration.new(-@seconds, -@months)
		end

		def +(other)
			Duration.new(@seconds+other.seconds, @months+other.months)
		end
		
		def -(other)
			Duration.new(@seconds-other.seconds, @months-other.months)
		end

		def *(other)
			Duration.new(@seconds*other, @months*other)
		end

		def /(other)
			Duration.new(@seconds/other, @months.div(other))
		end

		def seconds
			raise "Indetermined for mixed Durations" if mixed?
			@seconds
		end
		
		def minutes
			raise "Indetermined for mixed Durations" if mixed?
			(@seconds).quo(60)
		end
		
		def hours
			raise "Indetermined for mixed Durations" if mixed?
			(@seconds).quo(3600)
		end

		def days
			raise "Indetermined for mixed Durations" if mixed?
			(@seconds).quo(86400)
		end

		def weeks
			raise "Indetermined for mixed Durations" if mixed?
			(@seconds).quo(604800)
		end
		
		def months
			@months
		end
		
		def years
			Rational(@months, 12)
		end
		
		def seconds_after_minutes
			@seconds%60
		end

		def minutes_after_hours
			(@seconds%3600).quo(60)
		end
		
		def hours_after_days
			(@seconds%86400).quo(3600)
		end

		def days_after_weeks
			(@seconds%604800).quo(86400)
		end
		
		def months_after_years
			@months%12
		end
		
		# returns whether this Duration has both seconds and months component
		def mixed?
			@seconds != 0 && @months != 0
		end

		# returns 2 durations, first with stripped months, second with
		# stripped seconds
		# basically [self.strip_months, self.strip_seconds]
		def split
			[Duration.new(@seconds, 0), Duration.new(0, @months)]
		end

		# returns a duration without seconds part
		def strip_seconds
			Duration.new(0, @months)
		end

		# returns a duration without months part
		def strip_months
			Duration.new(@seconds, 0)
		end
		
		# creates an interval with fixed begin (use 2nd parameter to change that)
		# with the given datetime as begin and the given datetime+self as end
		def with_begin(datetime, fixed=:begin)
			Interval.new(datetime, datetime+self, fixed)
		end
		
		# creates an interval with fixed end (use 2nd parameter to change that)
		# with the given datetime-self as begin and the given datetime as end
		def with_end(datetime, fixed=:end)
			Interval.until(datetime-self, datetime, fixed)
		end

		# returns self as Duration
		def to_duration
			Duration.new(@seconds, @months)
		end
		
		# return a readable representation
		def to_s(inner_zeros=true, leading_zeros=false)
			if @months == 0 then
				elements = [
					[weeks.floor, "weeks", "week"],
					[days_after_weeks.floor, "days", "day"],
					[hours_after_days.floor, "hours", "hour"],
					[minutes_after_hours.floor, "minutes", "minute"],
					[seconds_after_minutes.floor, "seconds", "second"],
				]
				elements.shift while elements[0][0] == 0 unless leading_zeros
				elements.reject! { |count,x,y| count == 0 } unless inner_zeros
				elements.map {
					|count,plural,singular| "#{count} #{count == 1 ? singular : plural}"
				}.join(" ")
			elsif @seconds == 0 then
				elements = [
					[years.floor, "years", "year"],
					[months_after_years.floor, "months", "month"],
				]
				elements.shift while elements[0][0] == 0 unless leading_zeros
				elements.reject! { |count,x,y| count == 0 } unless inner_zeros
				elements.map {
					|count,plural,singular| "#{count} #{count == 1 ? singular : plural}"
				}.join(" ")
			else
				split.reverse.join(" ")
			end
		end
	end
end
