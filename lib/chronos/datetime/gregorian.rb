#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos

	# Example:
	#   require 'chronos/gregorian'
	#   date = Datetime.civil(year, month, day)
	#   datetime = date.at(hour, minute, second)
	#   datetimezonelanguage = datetime.in("Europe/Zurich", "de-de")
	#   dtz = Datetime.civil(y, m, d).at(hour, min, sec).in("Europe/Zurich", "de-de")
	#   datetime = Datetime.ordinal(year, day_of_year).at(0,0).in("UTC+1", "en-us")
	class Datetime
		class Gregorian < ::Chronos::Datetime
			ISO_8601_Datetime = "%04d-%02d-%02dT%02d:%02d:%02d-%02d:%02d".freeze
			ISO_8601_Date     = "%04d-%02d-%02d".freeze
			ISO_8601_Time     = "%02d:%02d:%02d-%02d:%02d".freeze
			Inspect           = "#<%s %s (%p, %p)>".freeze

			DAYS_IN_MONTH1    = [0,31,28,31,30,31,30,31,31,30,31,30,31].freeze
			DAYS_IN_MONTH2    = [0,31,29,31,30,31,30,31,31,30,31,30,31].freeze
			DAYS_UNTIL_MONTH1 = [0,31,59,90,120,151,181,212,243,273,304,334,365].freeze
			DAYS_UNTIL_MONTH2 = [0,31,60,91,121,152,182,213,244,274,305,335,366].freeze

			# symbol => index (reverse map for succ/current/previous)
			DAY_OF_WEEK = {
				:monday     => 0,
				:tuesday    => 1,
				:wednesday  => 2,
				:thursday   => 3,
				:friday     => 4,
				:saturday   => 5,
				:sunday     => 6,
			}.freeze
	
			# convert hours, minutes, seconds and fraction to picoseconds required by ::new
			def self.picoseconds(hour, minute, second, fraction=nil, offset=nil)
				(hour*3600+minute*60+second+(fraction||0)-(offset||0))*1_000_000_000_000
			end

			# returns the number of days in a given month for a given year
			def self.days_in_month(month, year=nil)
				(year.leap_year? ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1).at(month)
			end
			
			# returns the number of days since origin
			# TODO: check with negative years
			# TODO: use integer arithmetic only instead (divmod + test for zero)
			def self.days_since(year)
				year*365+(year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
			end
	
			# create a datetime with date part only from year, month and day_of_month
			# for timezone/language append a .in(timezone, language) or set a global
			# (see Chronos::Datetime)
			def self.civil(year, month, day_of_month)
				components(year, month, nil, nil, day_of_month, nil, nil, nil, nil)
			end
	
			# see Datetime#format
			# for timezone/language append a .in(timezone, language) or set a global
			# (see Chronos::Datetime)
			def self.commercial(year, week, day_of_week, year_is_commercial=true)
				raise ArgumentError, "Non commercial years are not yet supported" unless year_is_commercial
				components(year, nil, week, nil, nil, day_of_week, nil, nil, nil)
			end
	
			# create a datetime with date part only from year and day_of_year
			# for timezone/language append a .in(timezone, language) or set a global
			# (see Chronos::Datetime)
			def self.ordinal(year, day_of_year)
				components(year, nil, nil, day_of_year, nil, nil, nil, nil, nil)
			end

			# create a datetime with time part only from hour, minute, second,
			# fraction of second (alternatively you can use a float as second)
			# for timezone/language append a .in(timezone, language) or set a global
			# (see Chronos::Datetime)
			def self.at(hour, minute=0, second=0, fraction=0.0, timezone=nil, language=nil)
				new(nil,picoseconds(h,m,s,f), timezone=nil, language=nil)
			end
			
			# parses an ISO 8601 string
			# this can be either date, time or date and time
			# date parts must be fully qualified (year+month+day or year+day_of_year or
			# year+week+day_of_week)
			# this is in here too to be consistent with Datetime#to_s, for other parsers
			# see Chronos::Parse
			def self.iso_8601(string, language=nil)
				# date & time
				if string.include?('T') then
					case string
						#       (year          )   (month )   (day    )     hour       minute     second fraction      timezone
						when /\A(-?\d\d|-?\d{4})(?:-?(\d\d)(?:-?(\d\d))?)?T(\d\d)(?::?(\d\d)(?::?(\d\d(?:\.\d+)?)?)?)?(Z|[-+]\d\d:\d\d)?\z/
							year   = $1.to_i
							month  = $2.to_i
							day    = $3.to_i
							zone   = Chronos.timezone($7)
							ps     = picoseconds($4.to_i, $5.to_i, $6.include?('.') ? $6.to_f : $6.to_i, nil, zone.offset)
							components(year, month, nil, nil, day, nil, ps, zone, language)
						when /\A(-?\d\d|-?\d{4})(?:-?W(\d\d)(?:-?(\d))?)?T(\d\d)(?::?(\d\d)(?::?(\d\d(?:\.\d+)?)?)?)?(Z|[-+]\d\d:\d\d)?\z/
							year   = $1.to_i
							week   = $2.to_i
							day    = $3.to_i
							zone   = Chronos.timezone($7)
							ps     = picoseconds($4.to_i, $5.to_i, $6.include?('.') ? $6.to_f : $6.to_i, nil, zone.offset)
							components(year, nil, week, nil, nil, day, ps, zone, language)
						when /\A(-?\d\d|-?\d{4})(?:-?(\d{3}))?T(\d\d)(?::?(\d\d)(?::?(\d\d(?:\.\d+)?)?)?)?(Z|[-+]\d\d:\d\d)?\z/
							year   = $1.to_i
							day    = $2.to_i
							zone   = Chronos.timezone($6)
							ps     = picoseconds($3.to_i, $4.to_i, $5.include?('.') ? $5.to_f : $5.to_i, nil, zone.offset)
							components(year, nil, nil, day, nil, nil, ps, zone, language)
					end
				# date | time
				else
					case string
						when //
							components()
					end
				end
			end
			
			# Create a Datetime::Gregorian from parts.
			# Intended for constructors (parsers e.g.).
			def self.components(year, month, week, dayofyear, dayofmonth, dayofweek, ps_number, timezone, language)
				now        = Time.now
				day_number = nil

				# has date
				if year || month || week || dayofyear || dayofmonth || dayofweek then
					year ||= now.year

					# year-month-day_of_month
					if (month || dayofmonth) then
						month      ||= 1
						dayofmonth ||= 1
						# calculate how many days passed until this year
						leap  = year.leap_year?
						raise ArgumentError, "Invalid month (#{year}-#{month}-#{day_of_month})" if month < 1 or month > 12
						raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{dayofmonth})" if dayofmonth > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month]
						doy   = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month-1]+dayofmonth
						day_number = days_since(year)+doy

					# year-week-day_of_week
					elsif (week || dayofweek) then
						week      ||= 1
						dayofweek ||= 1
						fdy         = days_since(year)+1
						fwd         = (fdy+4)%7
						off         = (10-fwd)%7-3
						day_number  = fdy+off+(week-1)*7+dayofweek
					
					# year-day_of_year
					else
						dayofyear ||= 1
						day_number   = days_since(year)+dayofyear
					end
				end # has date
				new(day_number, ps_number, timezone, language)
			end
			
			# Slower than components() but more convenient.
			# parts for dates: :year, (:month, :day[_of_month] | :week, :day[_of_week] | :day[_of_year])
			# parts for time: :hour, :minute, :second, :fraction, :usec, (:offset | :timezone)
			# other parts: :language
			def self.named_components(components)
				components(components.values_at(
					:year,
					:month,
					:week,
					:day_of_year,
					:day_of_month,
					:day_of_week,
					:picosecond,
					:timezone,
					:language
				))
			end
	


			# add a/modify the time component to/of a date only datetime
			def at(hour, minute=0, second=0, fraction=0.0)
				overflow, second = *(hour*3600+minute*60+second+fraction-@timezone.offset).divmod(86400)
				self.class.new(
					@day_number+overflow,
					second*1_000_000_000_000,
					@timezone,
					@language
				)
			end

			# change to another timezone, also gives the opportunity to change language
			def change_zone(timezone=nil, language=nil)
				timezone ||= @timezone
				timezone = Zone[timezone] unless timezone.kind_of?(Zone)
				Datetime.new(@day_number, @ps_number, timezone, language)
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
				lookup        = year.leap_year? ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1
				doy           = day_of_year()
				month         = (day_of_year/31.0).ceil
				@month        = lookup[month] < doy ? month + 1 : month
				@day_of_month = doy - lookup[@month-1]
				[@month, @day_of_month]
			end
	
			# returns whether or not the year of this date is a leap-year
			def leap_year?
				year.leap_year?
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
							when 5: (year-1).leap_year? ? 53 : 52
							when 4: 53
							else    1
						end
					else # calculate week number
						off  = (10-fwd)%7-2   # calculate offset of the first week
						week = (doy-off).div(7)+1
						if week > 52 then
							week = (fwd == 3 || (leap_year? && fwd == 2)) ? 53 : 1
						end
						week
					end
				end
			end
			
			def weeks
				fwd  = (@day_number+@overflow-day_of_year+5)%7         # calculate weekday of first day in year
				(fwd == 3 || (leap_year? && fwd == 2)) ? 53 : 52
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
					@hour ||= (@ps_number.div(1_000_000_000_000)+@offset).div(3600)
				rescue => e
					raise NoTimePart unless @ps_number
					raise
				end
			end
	
			# the minute of the hour (0..59, if it has a time part)
			def minute
				begin
					@minute ||= (@ps_number.div(1_000_000_000_000)+@offset).div(60)%60
				rescue => e
					raise NoTimePart unless @ps_number
					raise
				end
			end
	
			# the minute of the minute (0..59, if it has a time part)
			def second
				begin
					@second ||= (@ps_number.div(1_000_000_000_000)+@offset)%60
				rescue => e
					raise NoTimePart unless @ps_number
					raise
				end
			end
			
			# the absolute fraction - the internal representation of the time
			# together with second_number
			def fraction
				begin
					@ps_number.divmod(1_000_000_000_000).last.quo(1_000_000_000_000)
				rescue => e
					raise NoTimePart unless @ps_number
					raise
				end
			end
	
			# the microseconds (0..999999, if it has a time part)
			def usec
				begin
					@ps_number.div(1_000_000).divmod(1_000_000).last
				rescue => e
					raise NoTimePart unless @ps_number
					raise
				end
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
							leap   = year.leap_year?
							raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month+1]
							leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
							doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month]+day_of_month
							Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
						when :year
							month = month()
							year  = (year()+step.floor).to_f
							leap  = year.leap_year?
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
						leap   = year.leap_year?
						raise ArgumentError, "Invalid day of month (#{year}-#{month}-#{day_of_month})" if day_of_month > (leap ? DAYS_IN_MONTH2 : DAYS_IN_MONTH1)[month+1]
						leaps  = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
						doy    = (leap ? DAYS_UNTIL_MONTH2 : DAYS_UNTIL_MONTH1)[month]+day_of_month
						Datetime.new(year*365+leaps+doy, @second_number, @timezone, @language)
					when :year
						month = month()
						year  = at.floor.to_f
						leap  = year.leap_year?
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
	
			# format(string, language, timezone)
			# format datetime, similar to strftime. Format strings can contain:
			#   %a: monthname, can be formatted like %s in sprintf
			#   %b: dayname, can be formatted like %s in sprintf
			#   %y: year, 4 digits (0000..9999)
			#       %-2y: last 2 digits
			#       %2y:  first 2 digits
			#   %m: month of year, 1..31, can be formatted as %d in sprintf
			#   %d: day of month, 1..31, can be formatted as %d in sprintf
			#   %j: day of year, 1..366, can be formatted as %d in sprintf
			#   %k: day of week, 0=monday, 6=sunday
			#       %+k: 1..7 (changes range from 0..6 to 1..7)
			#       %2k: 0=saturday, 2=monday, 6=friday
			#       %+2k: 1=saturday, 3=monday, 7=friday
			#   %w: week of year (iso 8601) 1..53, can be formatted as %d in sprintf
			#
			#   %H: hour of day, 0..23, can be formatted as %d in sprintf
			#   %I: hour of day, 1..12, can be formatted as %d in sprintf
			#   %M: minute of hour 0..59, can be formatted as %d in sprintf
			#   %S: second of minute, 0..59, can be formatted as %d in sprintf
			#   %O: offset in format ±HHMM
			#   %Z: timezone
			#   %P: meridian indicator (AM/PM)
			#
			#   %%: Literal % character
			def format(string=nil, language=nil)
				unless string
					string = if @day_number.nil? then
						ISO_8601_Time
					elsif @ps_number.nil? then
						ISO_8601_Date
					else
						ISO_8601_Datetime
					end
				end

				string.gsub(/%(%|\{[^}]\}|.*?[A-Za-z])/) { |m|
					case m[-1,1]
						when '{'
							call,*args = *m[2..-2].split(",")
							call       = c.to_sym
							args.map! { |arg|
								if arg[0,1] == ":" then
									arg[1..-1].to_sym
								elsif arg =~ /\A\d+\z/ then
									Integer(arg)
								else
									Float(arg)
								end
							}
	
							respond_to?(call)
							send(call, *args)
						when 'a'
							"#{m[0..-2]}s"%month_name
						when 'b'
							"#{m[0..-2]}s"%day_name
						when 'y'
							s = "%04d"%year
							if m.length > 2 then
								o = m[1..-2].to_i
								o > 0 ? s[0,o] : s[o..-1]
							else
								s
							end
						when 'm'
							"#{m[0..-2]}d"%month
						when 'd'
							"#{m[0..-2]}d"%day_of_month
						when 'j'
							"#{m[0..-2]}d"%day_of_year
						when 'k'
							dow = day_of_week
							dow = (dow+m[-2,1].to_i)%7 if (m[-2,1] =~ /\d/)
							dow += 1 if (m[1,1] == "+")
							dow
						when 'w'
							"#{m[0..-2]}d"%week
	
						when 'H'
							"#{m[0..-2]}d"%hour
						when 'I'
							"#{m[0..-2]}d"%(hour%12+1)
						when 'M'
							"#{m[0..-2]}d"%minute
						when 'S'
							"#{m[0..-2]}d"%second
						when 'O'
							"%s%02d%02d"%[@offset < 0 ? "-" : "+",@offset.div(3600),@offset.div(60)%60]
						when 'Z'
							"FIXME"
						when 'P'
							hour <= 12 ? "AM" : "PM"
						when '%'
							"%"
					end
				}
			end

			# prints the datetime as ISO-8601, examples:
			# datetime: 2007-01-31T14:31:25-04:00
			# date:     2007-01-31
			# time:     14:31:25-04:00
			def to_s
				if @day_number then
					if @ps_number then
						sprintf ISO_8601_Datetime, year, month, day, hour, minute, second, *(offset/60).floor.divmod(60)
					else
						sprintf ISO_8601_Date, year, month, day
					end
				else
					sprintf ISO_8601_Time, hour, minute, second, *(offset/60).floor.divmod(60)
				end
			end

			def inspect
				sprintf Inspect,
					self.class,
					self,
					@day_number,
					@ps_number
				# / sprintf
			end
		end # Datetime::Gregorian
	end # Datetime
end # Chronos
