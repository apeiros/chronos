#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Chronos

	# An Interval is determinated by a start and an end Datetime.
	# Unlike in Duration, this allows to determine the months part exactly in
	# seconds (and therefore minutes, hours, days, weeks).
	# That opens up the possibility to say how
	class Interval
		attr_reader :begin, :end, :fixed

		# unlike new, between doesn't care about what date is before the other,
		# it will switch them if date1 > date2
		def self.between(date1, date2)
			date1 > date2 ? new(date2, date1) : new(date1, date2)
		end

		# create a new interval that lasts from start_date until end_date
		# start_date *must* be <= end_date
		def initialize(start_date, end_date, fixed=:begin)
			raise ArgumentError, "begin after end" if start_date > end_date
			raise ArgumentError, "begin not same signature as end" unless start_date.time? == end_date.time? and start_date.date? == end_date.date?
			raise ArgumentError, "invalid fixed, must be :begin or :end" unless fixed == :begin or fixed == :end or fixed.nil?

			@begin = start_date
			@end   = end_date
			@fixed = fixed || :begin

			seconds = start_date.time? ? start_date.second_number - end_date.second_number : 0
			seconds_in_months = 0

			if start_date.date? then
				a, b     = Datetime.new(@begin.day_number,nil), Datetime.new(@end.day_number,nil)
				seconds += (b.day_number - a.day_number)*86400
				bsd      = a.day_of_month > b.day_of_month ||
				           (start_date.time? && a.day_of_month == b.day_of_month && seconds < 0)
				month1   = a.year*12+a.month+(bsd ? 1 : 0)
				month2   = b.year*12+b.month
				months   = month2 - month1
				a2y,a2m  = *(month1-1).divmod(12)
				a, b     = Datetime.civil(a2y, a2m+1, 1), Datetime.civil(b.year, b.month, 1)

				seconds_in_months = (b.day_number-a.day_number)*86400
				p [seconds, seconds_in_months]
				seconds -= seconds_in_months

				b2y,b2m  = *(month1+(months.div(12)*12)).divmod(12)
				b        = Datetime.civil(b2y, b2m+1, 1)
				seconds_in_years = (b.day_number-a.day_number)*86400
			end

			@seconds_in_years  = seconds_in_years
			@seconds_in_months = seconds_in_months
			@seconds = seconds
			@months  = months
		end

		# returns the same interval but with begin as fixpoint for math ops
		# like +, -, *, /
		def fix_begin
			self.class.new(@begin, @end, :begin)
		end

		# returns the same interval but with end as fixpoint for math ops
		# like +, -, *, /
		def fix_end
			self.class.new(@begin, @end, :end)
		end

		# Enlarges the Interval by duration away from the fixed end
		def +(duration)
			if @fixed == :begin then
				self.class.new(@begin, @end+duration, @fixed)
			else
				self.class.new(@begin-duration, @end, @fixed)
			end
		end

		# Shortens the Interval by duration towards from the fixed end
		# will raise if self < duration
		def -(duration)
			if @fixed == :begin then
				self.class.new(@begin, @end-duration, @fixed)
			else
				self.class.new(@begin+duration, @end, @fixed)
			end
		end

		# multiplies the primitives (seconds and months) of the
		# inherent duration and creates a new Interval from that and
		# the fixed end
		def *(numeric)
			if @fixed == :begin then
				self.class.new(@begin, @begin+to_duration*numeric, @fixed)
			else
				self.class.new(@end-to_duration*numeric, @end, @fixed)
			end
		end

		# divides the primitives (seconds and months) of the
		# inherent duration and creates a new Interval from that and
		# the fixed end
		def *(numeric)
			if @fixed == :begin then
				self.class.new(@begin, @begin+to_duration/numeric, @fixed)
			else
				self.class.new(@end-to_duration/numeric, @end, @fixed)
			end
		end

		# 0..Inf,  Integer
		def seconds
			@seconds + @seconds_in_months
		end

		# 0...60,  Integer
		def seconds_after_minutes
			(@seconds + @seconds_in_months)%60
		end

		# 0..Inf,  Rational (seconds included)
		def minutes
			(@seconds + @seconds_in_months).quo(60)
		end

		# 0...60,  Rational (seconds included)
		def minutes_after_hours
			((@seconds + @seconds_in_months)%3600).quo(60)
		end

		# 0..Inf,  Rational (minutes and seconds included)
		def hours
			(@seconds + @seconds_in_months).quo(3600)
		end

		# 0...24,  Rational (minutes and seconds included)
		def hours_after_days
			((@seconds + @seconds_in_months)%86400).quo(3600)
		end

		# 0..Inf,  Rational (minutes and seconds included)
		def days
			(@seconds + @seconds_in_months).quo(86400)
		end

		# 0...7,   Rational (smaller units included)
		def days_after_weeks
			((@seconds + @seconds_in_months)%604800).quo(86400)%7
		end

		# 0...31,  Rational (smaller units included)
		def days_after_months
			@seconds.quo(86400)
		end

		# example:
		#   birthsday = Chronos::Datetime.civil(year, month, day)
		#   interval  = Chronos::Datetime.today - birthsday
		#   puts "Days since your last birthsday: #{interval.days_after_years.floor}"
		# 0...366, Rational (smaller units included)
		def days_after_years
			(@seconds + @seconds_in_months - @seconds_in_years).quo(86400)
		end

		# 0..Inf,  Rational (smaller units included)
		def weeks
			(@seconds + @seconds_in_months).quo(604800)
		end

		# 0...5,    Rational (smaller units included)
		def weeks_after_months
			days_after_months.quo(7)
		end

		# 0...53
		def weeks_after_years
			days_after_years.quo(7)
		end

		# 0..Inf,  total months, Integer
		def months
			@months
		end

		# 0...12,  Integer
		def months_after_years
			@months%12
		end

		# 0..Inf,  Rational (months included)
		def years
			@months.quo(12)
		end

		# converts this interval to a duration
		# if you set as_seconds to true it will convert the
		# month primitive to seconds and use that
		def to_duration(as_seconds=false)
			if as_seconds then
				Duration.new(@seconds + @seconds_in_months)
			else
				Duration.new(@seconds, @months)
			end
		end

		# [...] sequences may include a single replacement. if that replacement is 0, the whole segment is omitted
		# [...>] sequences work the same, but are not omitted if there are optional replacements on the right side that haven't been omitted
		def format(string="[%{full_years} years >][%{months_after_years} months >][%{days_after_months} days >][%{hours_after_days}h>]%{minutes_after_hours}m>]%{seconds_after_minutes}s")

		end

		def inspect
			"<Interval #{@begin} - #{@end}, @months=#{@months}, @seconds=#{@seconds}>"
		end
	end
end
