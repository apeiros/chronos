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
				when ::Time
					time  = utc
					value = Chronos::Datetime.civil(time.year, time.month, time.day).
																		at(time.hour, time.min, time.sec, time.to_f%1)
					(timezone || language) ? value.in(timezone, language) : value
				when ::Date
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
		def self.today
			now = Time.now
			ordinal(now.year, now.yday)
		end

		# create a datetime with date and time part from a unix-epoch-stamp
		# for timezone/language append a .in(timezone, language) or set a global
		# (see Chronos::Datetime)
		def self.epoch(unix_epoch_time, timezone=nil, language=nil)
			import(Time.at(unix_epoch_time), timezone, language)
		end

		# parses an ISO 8601 string
		# this can be either date, time or date and time
		# date parts must be fully qualified (year+month+day or year+day_of_year or
		# year+week+day_of_week)
		# this is in here too to be consistent with Datetime#to_s, for other parsers
		# see Chronos::Parse
		def self.iso_8601(string)
			raise NoMethodError
		end
		
		# Parses a String in form of the XML Schema Date format to a Datetime.
		def self.xml_schema(string)
			raise NoMethodError
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

		# this method calculates @day_of_year and @year from @day_number - only used internally
		def year_and_day_of_year # :nodoc:
			raise NoDatePart unless @day_number
			y4c, days    = *(@day_number+@overflow-1).divmod(146097)

			if days == 0 then
				y1c, days = 0, 0
			else
				y1c, days    = *(days-1).divmod(36524)
				days += 1
			end

			y4,  days    = *days.divmod(1461)  # if y4 == 0: leapyear, else: not
			days -= 1 if (y1c != 0 && y4 == 0)

			if days == 0 then
				y1, days = 0, 0
			elsif (y1c != 0 && y4 == 0) then # no leapyear at start
				y1, days = *days.divmod(365)
			else
				y1, days = *(days-1).divmod(365)
				days += 1 if y1 == 0
			end
			@year        = y4c*400+y1c*100+y4*4+y1
			@day_of_year = days+1
			[@year, @day_of_year]
		end

		# this method calculates @day_of_month and @month from @day_number - only used internally
		def month_and_day_of_month # :nodoc:
			raise NoDatePart unless @day_number
			lookup        = Datetime.leap?(year) ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1
			doy           = day_of_year()
			month         = (day_of_year/31.0).ceil
			@month        = lookup[month] < doy ? month + 1 : month
			@day_of_month = doy - lookup[@month-1]
			[@month, @day_of_month]
		end

		# returns whether or not the year of this date is a leap-year
		def leap?
			Datetime.leap?(year)
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

		# the dayname in the given language or the Datetime-instances default language
		#   Datetime.civil(2000,1,1).day_name # => "Saturday"
		def day_name(language=nil)
			language ||= @language
			begin
				DAY_NAME[(@day_number+@overflow+4)%7]
			rescue
				raise NoDatePart unless @day_number
				raise
			end
		end

		# the monthname in the given language or the Datetime-instances default language
		# Datetime.civil(2000,1,1).month_name # => "January"
		def month_name(language=nil)
			MONTH_NAME[month-1]
		end

		# ISO 8601 week
		def week
			@week ||= begin
				doy  = day_of_year       # day of year
				fdy  = @day_number+@overflow-doy+1 # first day of year
				fwd  = (fdy+4)%7         # calculate weekday of first day in year
				if doy <= 3 && doy <= 7-fwd then  # last week of last year
					case fwd
						when 6: 52
						when 5: Datetime.leap?(year-1) ? 53 : 52
						when 4: 53
						else    1
					end
				else # calculate week number
					off  = (10-fwd)%7-2   # calculate offset of the first week
					week = (doy-off).div(7)+1
					if week > 52 then
						week = (fwd == 3 || (leap? && fwd == 2)) ? 53 : 1
					end
					week
				end
			end
		end
		
		def weeks
			fwd  = (@day_number+@overflow-day_of_year+5)%7         # calculate weekday of first day in year
			(fwd == 3 || (leap? && fwd == 2)) ? 53 : 52
		end

		# this dates day of month (if it has a date part)
		def day_of_month
			@day_of_month ||= month_and_day_of_month[1]
		end

		alias day day_of_month

		# this dates month (if it has a date part)
		def month
			@month ||= month_and_day_of_month[0]
		end

		# the hour of the day (0..23, if it has a time part)
		def hour
			begin
				@hour ||= (@second_number+@offset).div(3600)
			rescue => e
				raise NoTimePart unless @second_number
				raise
			end
		end

		# the minute of the hour (0..59, if it has a time part)
		def minute
			begin
				@minute ||= (@second_number+@offset).div(60)%60
			rescue => e
				raise NoTimePart unless @second_number
				raise
			end
		end

		# the minute of the minute (0..59, if it has a time part)
		def second
			begin
				@second ||= (@second_number+@offset)%60
			rescue => e
				raise NoTimePart unless @second_number
				raise
			end
		end
		
		# the absolute fraction - the internal representation of the time
		# together with second_number
		def fraction
			begin
				@second_number%1
			rescue => e
				raise NoTimePart unless @second_number
				raise
			end
		end

		# the microseconds (0..999999, if it has a time part)
		def usec
			begin
				(@second_number%1*1000000).round
			rescue => e
				raise NoTimePart unless @second_number
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

		# will raise if you try to do e.g.: Datetime.civil(2000,3,31).next(:month)
		# since april only has 30 days, so 2000,4,31 is invalid
		# same with Datetime.civil(2004,2,29).next(:year)
		# as in 2004, february has a leap-day, but not so in 2005
		def succeeding(unit, step=1, upper_limit=nil)
			if block_given?
				date = self
				if step > 0 then
					while((date = date.succeeding(unit,step)) < upper_limit)
						yield(date)
					end
				elsif step < 0 then
					while((date = date.succeeding(unit,step)) < upper_limit)
						yield(date)
					end
				else
					raise ArgumentError, "Step may not be 0"
				end
			else
				case unit
					when :second
						overflow, second_number = *(@second_number+step).divmod(86400)
						day_number = @day_number ? @day_number + overflow : nil
						Datetime.new(day_number, second_number, @timezone, @language)
					when :minute
						overflow, second_number = *(@second_number+(step*60)).divmod(86400)
						day_number = @day_number ? @day_number + overflow : nil
						Datetime.new(day_number, second_number, @timezone, @language)
					when :hour
						overflow, second_number = *(@second_number+(step*3600)).divmod(86400)
						day_number = @day_number ? @day_number + overflow : nil
						Datetime.new(day_number, second_number, @timezone, @language)
					when :day
						day_number = @day_number + step.floor
						Datetime.new(day_number, @second_number, @timezone, @language)
					when :monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday
						begin
							Datetime.new(@day_number+(DAY_OF_WEEK[unit]-@day_number-5)%7+1+7*(step >= 1 ? step-1 : step).floor, @second_number, @timezone, @language)
						rescue
							raise NoDatePart unless @day_number
							raise
						end
					when :week
						day_number = @day_number + step.floor*7
						Datetime.new(day_number, @second_number, @timezone, @language)
					when :month
						overflow, month = *(month()-1+step.floor).divmod(12)
						year   = (year()+overflow).to_f
						leap   = Datetime.leap?(year)
						raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month+1]
						leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
						doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month]+day_of_month
						Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
					when :year
						month = month()
						year  = (year()+step.floor).to_f
						leap  = Datetime.leap?(year)
						raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month]
						leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
						doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month-1]+day_of_month
						Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
				end
			end
		end

		# similar to Datetime#succ
		# returns a new date with the given unit altered as wished
		# Datetime#current tries to not modify any of the other parameters, i.e. no
		# overflows are passed down
		#
		def current(unit, at=0)
			case unit
				when :second
					fraction = at%1
					second_number = (@second_number-second+at.floor)
					Datetime.new(@day_number, second_number, fraction, @timezone, @language)
				when :minute
					second_number = (@second_number-(minute*60)+(at*60).floor)
					Datetime.new(@day_number, second_number, @timezone, @language)
				when :hour
					second_number = (@second_number-(hour*3600)+(at*3600).floor)
					Datetime.new(@day_number, second_number, @timezone, @language)
				when :day
					raise ArgumentError, "Does not make sense"
				when :monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday
					begin
						Datetime.new(@day_number-(@day_number+4)%7+DAY_OF_WEEK[unit], @second_number, @timezone, @language)
					rescue
						raise NoDatePart unless @day_number
						raise
					end
				when :week
					year = year().to_f
					leaps = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					fdy = year*365+leaps+1 # first day of year
					fwd = (fdy+4)%7 # first day of years weekday
					off = (10-fwd)%7-3   # calculate offset of the first week
					Datetime.new(fdy+off+at*7+day_of_week(), @second_number, @timezone, @language)
				when :month
					month  = at.floor
					year   = year().to_f
					leap   = Datetime.leap?(year)
					raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month+1]
					leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month]+day_of_month
					Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
				when :year
					month = month()
					year  = at.floor.to_f
					leap  = Datetime.leap?(year)
					raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month]
					leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month-1]+day_of_month
					Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
			end
		end

		# see Datetime#next
		def previous(unit, step=1, lower_limit=nil, &block)
			succeeding(unit, -step, lower_limit, &block)
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
			!@day_number.nil?
		end
		
		def time_only?
			@day_number.nil?
		end

		# true if this instance has a time part
		def time?
			!@second_number.nil?
		end

		def date_only?
			@second_number.nil?
		end

		# convert to ::Time (core Time class)
		# be aware that due to a lack of possibility to provide the
		# timezone, all results are returned
		# - in utc if this Datetime instance has a timezone set
		# - in the local timezone if this instance has no timezone set
		# will raise if the Datetime object is time_only?
		def to_time
			raise TypeError, "Can't convert a time_only? Datetime to Time" if time_only?
			ref   = @timezone ? self.class.new(@day_number, @second_number) : self
			items = [ref.year, ref.month, ref.day_of_month]
			items.push ref.hour, ref.minute, ref.second, ref.usec*1000000 if @second_number
			if @timezone then
				Time.utc(*items)
			else
				Time.local(*items)
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
