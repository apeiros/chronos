#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos

	# == Summary
	# Datetime represents dates, times and combinations thereof.
	#
	# == Synopsis Example:
	#   require 'chronos/gregorian'
	#   date = Datetime.civil(year, month, day)
	#   datetime = date.at(hour, minute, second)
	#   datetimezonelanguage = datetime.in("Europe/Zurich", "de-de")
	#   dtz = Datetime.civil(y, m, d).at(hour, min, sec).in("Europe/Zurich", "de-de")
	#   datetime = Datetime.ordinal(year, day_of_year).at(0,0).in("UTC+1", "en-us")
	#
	# == Description
	# A Datetime represents a singular point on a time axis which has its origin
	# on the backdated gregorian date 0000-01-01 (january 1st in the year 0).
	# A Datetime consists of the days and picoseconds since that origin.
	# The range of Datetimes ruby implementation is only limited by your memory, the
	# C implementation can represent any date within +/- 2^63 days around the origin.
	# That means you can have dates before the assumed beginning of this universe which
	# should be enough even for scientific purposes.
	#
	# == Notes
	# The methods <, <=, ==, >=, > and between? are implemented via Comparable
	# Chronos::Datetime is calendar system agnostic and does NOT provide any calendar specific
	# methods, use the subclasses such as Datetime::Gregorian for those.
	#
	class Datetime

		Inspect = "#<%s daynumber=%p picosecondnumber=%p timezone=%p language=%p>".freeze

		include Comparable
		
		# Delegate all methods to the current calendary 
		def self.method_missing(*args, &block)
			calendar = Chronos.calendar
			if calendar && klass = const_get(calendar) then
				klass.__send__(*args, &block)
			else
				super
			end
		end

		# Convert a Date, DateTime or Time to Chronos::Datetime object
		def self.import(obj, timezone=nil, language=nil)
			case obj
				when ::Chronos::Datetime
					if obj.class == self.class then
						obj
					else
						new(obj.day_number, obj.ps_number, timezone||obj.timezone, language||obj.language)
					end
					
				# uses Chronos::Datetime::Gregorian::ordinal and Chronos::Datetime::Gregorian::time's code
				when ::Time
					time        = obj.utc
					year        = time.year
					day_of_year = time.yday
					leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					daynumber   = year*365+leaps+day_of_year
					ps_number    = ((time.hour*3600+time.min*60+time.sec)*1_000_000+time.usec)*1_000_000
					new(daynumber, ps_number, timezone || time.strftime("%Z"), language)

				# uses Chronos::Datetime::Gregorian::ordinal and Chronos::Datetime::Gregorian::time's code
				when ::DateTime
					year           = obj.year
					day_of_year    = obj.yday
					leaps          = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					daynumber      = year*365+leaps+day_of_year
					seconds        = (obj.hour*3600+obj.min*60+obj.sec+(obj.sec_fraction*86400).to_f)
					over, seconds  = (seconds-(obj.offset*86400).to_i).divmod(86400)
					ps_number       = seconds*1_000_000_000_000
					daynumber     += over
					new(daynumber, ps_number, timezone || obj.strftime("%Z"), language)

				# uses Chronos::Datetime::Gregorian::ordinal's code
				when ::Date # *must* be after ::DateTime as ::DateTime is a child of ::Date and would trigger on this too
					year        = obj.year
					day_of_year = obj.yday
					leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
					daynumber   = year*365+leaps+day_of_year
					new(daynumber, nil, timezone, language)
			end
		end
		
		# create a datetime with date and time part set to the current system time
		# and date
		def self.now(timezone=nil, language=nil)
			import(Time.now, timezone, language)
		end

		# create a datetime with only the date part set to the current system date
		# for timezone/language append a .in(timezone, language) or set a global
		# (see Chronos::Datetime)
		def self.today(timezone=nil, language=nil)
			# uses Chronos::Datetime::Gregorian::ordinal's code
			time        = Time.now.utc
			year        = time.year
			day_of_year = time.yday
			leaps       = (year/4.0).ceil-(year/100.0).ceil+(year/400.0).ceil
			daynumber   = year*365+leaps+day_of_year
			new(daynumber, nil, timezone || time.strftime("%Z"), language)
		end

		# create a datetime with date and time part from a unix-epoch-stamp
		# for timezone/language append a .in(timezone, language) or set a global
		# (see Chronos::Datetime)
		def self.epoch(unix_epoch_time, timezone=nil, language=nil)
			import(Time.at(unix_epoch_time), timezone, language)
		end
		
		# From a hash with components, mainly intended for parsers.
		# Datetime::components accepts :daynumber, :picosecondnumber, :timezone and :language
		# Also see each calendar systems class for what parts they accept, e.g.
		# Chronos::Datetime::Gregorian::components.
		def self.components(components)
			daynumber, ps_number, timezone, language = *components.values_at(:daynumber, :picosecondnumber, :timezone, :language)
			raise ArgumentError, "Neither :daynumber nor :picosecondnumber given" unless (daynumber or ps_number)
			new(daynumber, ps_number, timezone, language)
		end

		# the absolute day_number - the internal representation of the date
		attr_reader :day_number
		# the absolute second_number - the internal representation of the time
		# together with fraction
		attr_reader :ps_number

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
		def initialize(day, picosecond, timezone=nil, language=nil)
			@day_number = day ? day.round : nil
			@ps_number  = picosecond ? picosecond.round : nil
			@timezone   = Chronos.timezone(timezone)
			@language   = Chronos.language(language)
			@offset     = (@timezone && @timezone.offset) || 0
			if @ps_number then
				@overflow = (@ps_number.div(1_000_000_000_000)+@offset).div(86400)
			else
				@overflow = 0 # overflow is created by time + timezone offset + dst
			end
		end

		# add a/modify the time component to/of a date only datetime
		def at(hour, minute=0, second=0, fraction=0.0)
			Datetime.new(
				@day_number,
				(hour*3600+minute*60+second+fraction)*1_000_000_000_000,
				@timezone,
				@language
			)
		end

		# converts the datetime object to given timezone/language
		# keeps the time the same as is, if you want to know the corresponding time
		# for a given other timezone, see #change_zone
		# TODO: go over this again, seems wrong
		def in(timezone=nil, language=nil)
			timezone = Chronos.timezone(timezone)
			if timezone then
				overflow, ps_number = *(@ps_number-timezone.offset*1_000_000_000_000).divmod(86400_000_000_000_000)
			else
				overflow  = 0
				ps_number = @ps_number
			end
			Datetime.new(@day_number+overflow, second_number, timezone, language)
		end
		
		# Change to another timezone, also gives the opportunity to change language
		def change_zone(timezone=nil, language=nil)
			timezone ||= @timezone
			timezone = Zone[timezone] unless timezone.kind_of?(Zone)
			Datetime.new(@day_number, @ps_number, timezone, language)
		end

		# returns a date-only datetime from this
		def strip_time
			raise TypeError, "This Datetime does not contain a date" unless @day_number
			Datetime.new(@day_number+@overflow, nil, @timezone, @language)
		end

		# returns a time-only datetime from this
		def strip_date
			raise TypeError, "This Datetime does not contain a time" unless @ps_number
			Datetime.new(nil, @ps_number, @timezone, @language)
		end

		# You can add a Duration
		def +(duration)
			duration      = duration.to_duration
			tmp           = self.class.new(@day_number, @ps_number)
			years, months = (tmp.month+duration.months-1).divmod(12)
			days, sec     = (@ps_number+duration.picoseconds).divmod(86400)
			tmp           = self.class.civil(tmp.year+years,tmp.months+1,tmp.day)
			day_number    = temporary.day_number+days
			self.class.new(day_number, sec, @timezone, @language)
		end

		def -(other)
			if other.respond_to?(:to_duration) then
				duration      = other.to_duration
				tmp           = self.class.new(@day_number, @ps_number)
				years, months = (tmp.month-duration.months-1).divmod(12)
				days, sec     = (@ps_number-duration.picoseconds).divmod(86400)
				tmp           = self.class.civil(tmp.year+years,tmp.months+1,tmp.day)
				day_number    = temporary.day_number+days
				self.class.new(day_number, sec, @timezone, @language)
			else
				Interval.between(self, self.class.import(other))
			end
		end

		# compare two datetimes.
		# not allowed if only one of both doesn't have no date.
		# if only one of both doesn't have time, 0h 0m 0.0s is used as time.
		def <=>(other)
			return nil if @day_number.nil? ^ other.day_number.nil? # either both or none must be nil
			[@day_number||0,@ps_number||0] <=> [other.day_number||0, other.ps_number||0]
		end

		# true if this instance has date and time part
		def datetime?
			@day_number && @ps_number
		end

		# true if this instance has a date part
		def date?
			!!@day_number # we do not expose the internal structure, not that somebody starts relying on it returning the daynumber
		end
		
		# true if this instance has a time part
		def time?
			!!@ps_number # we do not expose the internal structure, not that somebody starts relying on it returning the picosecondnumber
		end

		# convert to ::Time (core Time class)
		# be aware that due to a lack of possibility to provide the
		# timezone, all results are returned
		# - in utc if this Datetime instance has a timezone set
		# - in the local timezone if this instance has no timezone set
		# will raise if the Datetime object is time_only?
		# TODO: make independent of Datetime::Gregorian
		def export(to_class)
			if to_class == Time then
				raise TypeError, "Can't export a Datetime without date part to Time" unless date?
				ref   = ::Chronos::Datetime::Gregorian.new(@day_number, @ps_number)
				items = [ref.year, ref.month, ref.day_of_month]
				items.push ref.hour, ref.minute, ref.second, ref.usec*1000000 if @ps_number
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
			sprintf Inspect, self.class, @day_number, @ps_number, @timezone, @language
		end
		
		def eql?(other) # :nodoc:
			@ps_number  == other.ps_number &&
			@day_number == other.day_number &&
			@timezone   == other.timezone &&
			@language   == other.language
		end
	end
end
