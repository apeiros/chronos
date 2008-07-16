#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos


	# Datetime represents singular points on a time axis which has its origin
	# on backdated gregorian year 0, january 1st.
	# A Datetime consists of the days and seconds since that origin.
	#
	# Example:
	#   require 'chronos/gregorian'
	#   date = Datetime.civil(year, month, day)
	#   datetime = date.at(hour, minute, second)
	#   datetimezonelanguage = datetime.in("Europe/Zurich", "de-de")
	#   dtz = Datetime.civil(y, m, d).at(hour, min, sec).in("Europe/Zurich", "de-de")
	#   datetime = Datetime.ordinal(year, day_of_year).at(0,0).in("UTC+1", "en-us")
	class Datetime

		Inspect = "#<%s daynumber=%p picosecondnumber=%p timezone=%p language=%p>".freeze

		include Comparable
		
		# Delegate all methods to the current calendary 
		def self.method_missing(*args, &block)
			if klass = const_get(Chronos.calendar) then
				klass.__send__(*args, &block)
			else
				super
			end
		end

		# Convert a Date, DateTime or Time to Chronos::Datetime object
		def self.import(obj, timezone=nil, language=nil)
			case obj
				# uses Chronos::Datetime::Gregorian::ordinal and Chronos::Datetime::Gregorian::time's code
				when ::Time
					time        = obj.utc
					year        = time.year
					day_of_year = time.yday
					leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					hour*3600+minute*60+second+fraction
					new(daynumber, picosecondnumber, timezone || time.strftime("%Z"), language)

				# uses Chronos::Datetime::Gregorian::ordinal's code
				when ::Date
					year        = obj.year
					day_of_year = obj.yday
					leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					new(year*365+leaps+day_of_year, timezone, language)

				# uses Chronos::Datetime::Gregorian::ordinal and Chronos::Datetime::Gregorian::time's code
				when ::DateTime
			end
		end

		# create a datetime with date and time part set to the current system time
		# and date
		def self.now(timezone=nil, language=nil)
			import(Time.now, timezone, language)
		end

		# create a datetime with only the date part set to the current system date
		# for timezone/language append a .in(timezone, language) or set a global
		# (see Chronos::Datetime)
		def self.today(timezone=nil, language=nil)
			# uses Chronos::Datetime::Gregorian::ordinal's code
			time        = obj.utc
			year        = time.year
			day_of_year = time.yday
			leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
			daynumber   = year*365+leaps+day_of_year
			new(daynumber, nil, timezone || time.strftime("%Z"), language)
		end

		# create a datetime with date and time part from a unix-epoch-stamp
		# for timezone/language append a .in(timezone, language) or set a global
		# (see Chronos::Datetime)
		def self.epoch(unix_epoch_time, timezone=nil, language=nil)
			import(Time.at(unix_epoch_time), timezone, language)
		end
		
		# from a hash with components, mainly intended for parsers
		# parts for dates must either be all or none set, time are all optional, others
		# also.
		# parts for dates: :year, (:month, :day[_of_month] | :week, :day[_of_week] | :day[_of_year])
		# parts for time: :hour, :minute, :second, :fraction, :usec, (:offset | :timezone)
		# other parts: :language
		def self.components(components)
			raise NoMethodError
		end

		# the absolute day_number - the internal representation of the date
		attr_reader :day_number
		# the absolute second_number - the internal representation of the time
		# together with fraction
		attr_reader :second_number

		# the amount of days the dates representation is shifted (caused by a time-
		# part with an offset that 'overflows' into the previous or next day)
		attr_reader :overflow
		# the amount of seconds the times representation is shifted
		attr_reader :offset

		# the Zone instance used to retrieve offset
		attr_reader :timezone
		# the language used to output names (weekday-names, month-names)
		attr_reader :language

		# Create a new datetime from daynumber, secondnumber, timezone and language
		def initialize(day, second, timezone=nil, language=nil)
			@day_number    = day ? day.round : nil
			@second_number = second ? second.round : nil
			@timezone      = (timezone || Thread.current[:timezone] || $timezone || ENV['timezone'] || nil).freeze
			@language      = (language || Thread.current[:language] || $language || ENV['language'] || "en-us").freeze
			@offset        = @timezone && @timezone.offset ? @timezone.offset : 0
			if @second_number then
				@overflow = (@second_number+@offset).div(86400)
			else
				@overflow = 0 # overflow is created by time + timezone offset
			end
		end

		# add a/modify the time component to/of a date only datetime
		def at(hour, minute=0, second=0, fraction=0.0)
			Datetime.new(
				@day_number,
				hour*3600+minute*60+second+fraction,
				@timezone,
				@language
			)
		end

		# converts the datetime object to given timezone/language
		def in(timezone=nil, language=nil)
			timezone = Zone[timezone] unless timezone.kind_of?(Zone) or timezone.nil?
			if timezone then
				overflow, second_number = (@second_number-timezone.offset).divmod(86400)
			else
				overflow, second_number = 0, @second_number
			end
			Datetime.new(@day_number+overflow, second_number, timezone, language)
		end
		
		# change to another timezone, also gives the opportunity to change language
		def change_zone(timezone=nil, language=nil)
			timezone ||= @timezone
			timezone = Zone[timezone] unless timezone.kind_of?(Zone)
			Datetime.new(@day_number, @second_number, timezone, language)
		end

		# returns whether or not the year of this date is a leap-year
		def leap?
			year.leap?
		end

		# the gregorian year of this date (only limited by memory)
		def year
			@year ||= year_and_day_of_year[0]
		end
		
		# the gregorian commercial year - always starts with a monday, always
		# ends with a sunday, has either exactly 52 or 53 weeks.
		def commercial_year
			if week == 1 && day_of_year > 14
				year+1
			elsif week > 51 && day_of_year < 14 then
				year-1
			else
				year
			end
		end

		# the gregorian day of year (1-366)
		def day_of_year
			@day_of_year ||= year_and_day_of_year[1]
		end

		# the day of week of this date. 0: monday, 6: sunday
		# 7 days, 2000-01-01 beeing a 5 (saturday)
		# the additional parameter can be used to shift the monday to that number
		def day_of_week(monday=0)
			begin
				(@day_number+@overflow+4+monday)%7
			rescue
				raise NoDatePart unless @day_number
				raise
			end
		end

		# returns a date-only datetime from this
		def strip_time
			Datetime.new(@day_number+@overflow, nil, @timezone, @language)
		end

		# returns a time-only datetime from this
		def strip_date
			Datetime.new(nil, @second_number, @timezone, @language)
		end

		def +(duration)
			duration  = duration.to_duration
			tmp           = self.class.new(@day_number, @second_number)
			years, months = (tmp.month+duration.months-1).divmod(12)
			days, sec     = (@second_number+duration.seconds).divmod(86400)
			tmp           = self.class.civil(tmp.year+years,tmp.months+1,tmp.day)
			day_number    = temporary.day_number+days
			self.class.new(day_number, sec, @timezone, @language)
		end

		def -(other)
			if other.respond_to?(:to_duration) then
				duration      = other.to_duration
				tmp           = self.class.new(@day_number, @second_number)
				years, months = (tmp.month-duration.months-1).divmod(12)
				days, sec     = (@second_number-duration.seconds).divmod(86400)
				tmp           = self.class.civil(tmp.year+years,tmp.months+1,tmp.day)
				day_number    = temporary.day_number+days
				self.class.new(day_number, sec, @timezone, @language)
			elsif other.kind_of?(Datetime) then
				Interval.between(self, other)
			else
				raise TypeError, "Can't coerce #{other} to Duration or Datetime."
			end
		end

		# see <=>
		def ==(other)
			(self.<=>(other)) == 0
		end

		# compare two datetimes.
		# not allowed if only one of both doesn't have no date.
		# if only one of both doesn't have time, 0h 0m 0.0s is used as time.
		def <=>(other)
			if @day_number.nil?
				if other.day_number.nil?
					dn1, dn2 = 0,0
				else
					return nil #raise ArgumentError, "Comparing time only datetime to datetime"
				end
			elsif other.day_number.nil?
				return nil #raise ArgumentError, "Comparing time only datetime to datetime"
			else
				dn1, dn2 = @day_number, other.day_number
			end

			[dn1,@second_number||0] <=> [dn2, other.second_number||0]
		end

		# true if this instance has date and time part
		def datetime?
			@day_number && @second_number
		end

		# true if this instance has a date part
		def date?
			!!@day_number
		end
		
		# true if this instance has a time part
		def time?
			!!@second_number
		end

		# convert to ::Time (core Time class)
		# be aware that due to a lack of possibility to provide the
		# timezone, all results are returned
		# - in utc if this Datetime instance has a timezone set
		# - in the local timezone if this instance has no timezone set
		# will raise if the Datetime object is time_only?
		def export(to_class)
			if to_class == Time then
				raise TypeError, "Can't export a Datetime without date part to Time" unless date?
				ref   = @timezone ? self.class.new(@day_number, @second_number) : self
				items = [ref.year, ref.month, ref.day_of_month]
				items.push ref.hour, ref.minute, ref.second, ref.usec*1000000 if @second_number
				if @timezone then
					Time.utc(*items)
				else
					Time.local(*items)
				end
			elsif to_class == DateTime then
			elsif to_class == Date
			else
				raise ArgumentError, "Can't export to #{to_class}"
			end
		end
		
		def inspect
			sprintf Inspect, "#<#{self.class} #{date} #{time} (#{@day_number.inspect}, #{@second_number.inspect})>"
		end
		
		# :nodoc:
		def eql?(other)
			@second_number == other.second_number &&
			@day_number    == other.day_number &&
			@timezone      == other.timezone &&
			@language      == other.language
		end
	end
end
