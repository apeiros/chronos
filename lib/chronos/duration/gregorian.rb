#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos
	class Duration

		class Gregorian < ::Chronos::Duration
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
			After = Hash.new { |h,(a,b)| raise ArgumentError, "Can't get #{a} after #{b}" }.merge({
				[:picoseconds, :nanoseconds]   =>                   1_000,
				[:picoseconds, :microseconds]  =>               1_000_000,
				[:picoseconds, :milliseconds]  =>           1_000_000_000,
				[:picoseconds, :seconds]       =>       1_000_000_000_000,
				[:picoseconds, :minutes]       =>      60_000_000_000_000,
				[:picoseconds, :hours]         =>   3_600_000_000_000_000,
				[:picoseconds, :days]          =>  86_400_000_000_000_000,
				[:picoseconds, :weeks]         => 345_600_000_000_000_000,
				[:nanoseconds, :microseconds]  =>                   1_000,
				[:nanoseconds, :milliseconds]  =>               1_000_000,
				[:nanoseconds, :seconds]       =>           1_000_000_000,
				[:nanoseconds, :minutes]       =>          60_000_000_000,
				[:nanoseconds, :hours]         =>       3_600_000_000_000,
				[:nanoseconds, :days]          =>      86_400_000_000_000,
				[:nanoseconds, :weeks]         =>     345_600_000_000_000,
				[:microseconds, :milliseconds] =>                   1_000,
				[:microseconds, :seconds]      =>               1_000_000,
				[:microseconds, :minutes]      =>              60_000_000,
				[:microseconds, :hours]        =>           3_600_000_000,
				[:microseconds, :days]         =>          86_400_000_000,
				[:microseconds, :weeks]        =>         345_600_000_000,
				[:milliseconds, :seconds]      =>                   1_000,
				[:milliseconds, :minutes]      =>                  60_000,
				[:milliseconds, :hours]        =>               3_600_000,
				[:milliseconds, :days]         =>              86_400_000,
				[:milliseconds, :weeks]        =>             345_600_000,
				[:seconds, :minutes]           =>                      60,
				[:seconds, :hours]             =>                   3_600,
				[:seconds, :days]              =>                  86_400,
				[:seconds, :weeks]             =>                 345_600,
				[:minutes, :hours]             =>                      60,
				[:minutes, :days]              =>                   1_440,
				[:minutes, :weeks]             =>                  10_080,
				[:hours, :days]                =>                      24,
				[:hours, :weeks]               =>                     168,
				[:days, :weeks]                =>                       7,
				[:months, :years]              =>                      12,
			})
	
			def self.with(parts)
				y,m,w,d,h,min,s,ms,us,ns,ps = *Hash.new(0).merge(parts).values_at(
					:years,
					:months,
					:weeks,
					:days,
					:hours,
					:minutes,
					:seconds,
					:milliseconds,
					:microseconds,
					:nanoseconds,
					:picoseconds
				)
				seconds = s+min*60+h*3600+d*86400+w*604800
				ps     += s*1_000_000_000_000+ms*1_000_000_000+us*1_000_000+ns*1_000
				months  = m+y*12
				new(ps, months, parts[:language])
			end
			
			# seconds+months
			def initialize(picoseconds, months=0, language=nil)
				super(picoseconds, language)
				@months = months
			end

			def picoseconds(after=nil)
				after ? picoseconds%After[[:picoseconds, after]] : @picoseconds
			end

			def nanoseconds(after=nil)
				after ? nanoseconds%After[[:nanoseconds, after]] : @picoseconds.quo(PS_IN_NANOSECOND)
			end

			def microseconds(after=nil)
				after ? microseconds%After[[:microseconds, after]] : @picoseconds.quo(PS_IN_MICROSECOND)
			end

			def milliseconds(after=nil)
				after ? milliseconds%After[[:milliseconds, after]] : @picoseconds.quo(PS_IN_MILLISECOND)
			end

			def seconds(after=nil)
				after ? seconds%After[[:seconds, after]] : @picoseconds.quo(PS_IN_SECOND)
			end
			
			def minutes(after=nil)
				after ? minutes%After[[:minutes, after]] : @picoseconds.quo(PS_IN_MINUTE)
			end
			
			def hours(after=nil)
				after ? hours%After[[:hours, after]] : @picoseconds.quo(PS_IN_HOUR)
			end
	
			def days(after=nil)
				after ? days%After[[:days, after]] : @picoseconds.quo(PS_IN_DAY)
			end
	
			def weeks
				@picoseconds.quo(PS_IN_WEEK)
			end
			
			def months(after=nil)
				after ? days%After[[:days, after]] : @months
			end
			
			def years
				@months.quo(12)
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

		end # Datetime::Gregorian
	end # Datetime
end # Chronos
