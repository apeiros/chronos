#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'
require 'chronos/calendar/gregorian'
require 'chronos/datetime/gregorian'
require 'chronos/duration/gregorian'



module Chronos
	class Duration

		class Gregorian < ::Chronos::Duration
			FormatToS     = "%dps %d months (%s)".freeze
			FormatInspect = "#<%s:0x%08x %dps %d months (%s)>".freeze
			ShortTime     = ["%d".freeze, "%02d".freeze, "%02d".freeze, "%02d".freeze].freeze

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
				0,        # 0 days
				2678401,  # 31 days + leapsecond (june/december)
				5356800,  # 62 days (july, august)
				7948801,  # 92 days + leapsecond (june, july, august)
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
				[:picoseconds,  :nanoseconds]  =>                   1_000,
				[:picoseconds,  :microseconds] =>               1_000_000,
				[:picoseconds,  :milliseconds] =>           1_000_000_000,
				[:picoseconds,  :seconds]      =>       1_000_000_000_000,
				[:picoseconds,  :minutes]      =>      60_000_000_000_000,
				[:picoseconds,  :hours]        =>   3_600_000_000_000_000,
				[:picoseconds,  :days]         =>  86_400_000_000_000_000,
				[:picoseconds,  :weeks]        => 345_600_000_000_000_000,
				[:nanoseconds,  :microseconds] =>                   1_000,
				[:nanoseconds,  :milliseconds] =>               1_000_000,
				[:nanoseconds,  :seconds]      =>           1_000_000_000,
				[:nanoseconds,  :minutes]      =>          60_000_000_000,
				[:nanoseconds,  :hours]        =>       3_600_000_000_000,
				[:nanoseconds,  :days]         =>      86_400_000_000_000,
				[:nanoseconds,  :weeks]        =>     345_600_000_000_000,
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
				[:seconds,      :minutes]      =>                      60,
				[:seconds,      :hours]        =>                   3_600,
				[:seconds,      :days]         =>                  86_400,
				[:seconds,      :weeks]        =>                 345_600,
				[:minutes,      :hours]        =>                      60,
				[:minutes,      :days]         =>                   1_440,
				[:minutes,      :weeks]        =>                  10_080,
				[:hours,        :days]         =>                      24,
				[:hours,        :weeks]        =>                     168,
				[:days,         :weeks]        =>                       7,
				[:months,       :years]        =>                      12,
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
				seconds  = s+min*60+h*3600+d*86400+w*604800
				ps      += seconds*1_000_000_000_000+ms*1_000_000_000+us*1_000_000+ns*1_000
				days, ps = ps.divmod(PS_IN_DAY)
				months   = m+y*12
				new(months, days, ps, parts[:language])
			end
			
			def self.import(duration)
				duration.respond_to?(:to_gregorian_duration) ? duration.to_gregorian_duration : super
			end
			
			# seconds+months
			def initialize(months, days, picoseconds, language=nil)
				super(days, picoseconds, language)
				@months = months
			end

			def picoseconds(after=nil)
				after ? picoseconds%After[[:picoseconds, after]] : @picoseconds+@days*PS_IN_DAY
			end

			def nanoseconds(after=nil)
				after ? nanoseconds%After[[:nanoseconds, after]] : picoseconds.quo(PS_IN_NANOSECOND)
			end

			def microseconds(after=nil)
				after ? microseconds%After[[:microseconds, after]] : picoseconds.quo(PS_IN_MICROSECOND)
			end

			def milliseconds(after=nil)
				after ? milliseconds%After[[:milliseconds, after]] : picoseconds.quo(PS_IN_MILLISECOND)
			end

			def seconds(after=nil)
				after ? seconds%After[[:seconds, after]] : picoseconds.quo(PS_IN_SECOND)
			end
			
			def minutes(after=nil)
				after ? minutes%After[[:minutes, after]] : picoseconds.quo(PS_IN_MINUTE)
			end
			
			def hours(after=nil)
				after ? hours%After[[:hours, after]] : picoseconds.quo(PS_IN_HOUR)
			end
	
			def days(after=nil)
				after ? days%After[[:days, after]] : picoseconds.quo(PS_IN_DAY)
			end
	
			def weeks
				picoseconds.quo(PS_IN_WEEK)
			end
			
			def months(after=nil)
				after ? days%After[[:days, after]] : @months
			end
			
			def years
				@months.quo(12)
			end
			
			def decades
				@months.quo(144)
			end

			def centuries
				@months.quo(1200)
			end
			
			def to_duration
				Duration.new(@days, @picoseconds, @language)
			end
			
			def to_gregorian_duration
				self
			end
			
			def to_a(exclude_language=nil)
				exclude_language ? [@picoseconds, @months] : [@picoseconds, @months, @language]
			end
			
			def to_hash
				{
					:years        => years,
					:months       => @months,
					:weeks        => weeks,
					:days         => days,
					:hours        => hours,
					:minutes      => minutes,
					:seconds      => seconds,
					:milliseconds => milliseconds,
					:microseconds => microseconds,
					:nanoseconds  => nanoseconds,
					:picoseconds  => @picoseconds,
					:language     => @language,
				}
			end
			
			# Return a String in form of DDD:HH:MM:SS.fff
			# fraction_digits:: How many digits to display after the ., defaults to 0
			# num_elements::    How many elements to display at least
			#  * 1 is only SS
			#  * 2 is MM:SS
			#  * 3 is HH:MM:SS
			#  * 4 is DDD:HH:SS
			def short_time(fraction_digits=nil, num_elements=nil)
				elements = [
					days.floor,
					hours(:days).floor,
					minutes(:hours).floor,
					seconds(:minutes)
				]
				elements.shift while (elements.size > num_elements && elements.first.first.zero?)
				display = ShortTime[-elements.size..-1]
				display[-1] = "%#{fraction_digits+3}.#{fraction_digits}f" if (fraction_digits && fraction_digits > 0)
				sprintf(display.join(":"), *elements)
			end
			
			# return a readable representation
			def to_s(drop=:all_zeros, language=nil)
				elements1 = @months.zero? ? [] : [
					[years.floor,             :year],
					[days(:weeks).floor,      :month],
				]
				elements2 = @picoseconds.zero? ? [] : [
					[weeks.floor,                      :week],
					[days(:weeks).floor,               :day],
					[hours(:days).floor,               :hour],
					[minutes(:hours).floor,            :minute],
					[seconds(:minutes).floor,          :second],
					[milliseconds(:seconds).floor,     :millisecond],
					[microseconds(:milliseconds).floor, :microseconds],
					[nanoseconds(:microseconds).floor,  :nanosecond],
					[picoseconds(:nanoseconds).floor,   :picosecond],
				]
				elements = elements1+elements2
				case drop
					when :all_zeros
						elements.reject! { |count,*rest| count.zero? }
					when :leading_zeros
						elements.shift while elements.first.first.zero?
					when nil
					else
						raise ArgumentError, "Unknown directive, #{drop.inspect}"
				end
				elements.empty? ? "0" : elements.map { |count, unit|
					"#{count} #{Chronos.string(language ? Chronos.language(language) : @language, unit, count)}"
				}.join(", ")
			end
		end # Datetime::Gregorian
	end # Datetime
end # Chronos
