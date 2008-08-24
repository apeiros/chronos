#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Chronos
	class Interval

		# A Gregorian Interval extens Interval by months.
		# Unlike in Gregorian Durations, months exactly defined in seconds (and therefore minutes,
		# hours, days, weeks).
		# Internally a gregorian interval is stored as total picoseconds after days + days between the
		# two dates and additionally the months + days after months + picoseconds after days. For
		class Gregorian < Interval
			ValidFixed = [:begin, :end].freeze
	
			# The smaller of the two datetimes
			attr_reader :begin
			
			# The bigger of the two datetimes
			attr_reader :end
			
			# Which end is fixed, plays a role when adding, subtracting, multiplying, dividing, ...
			attr_reader :fixed
	
			# unlike new, between always creates a positive interval
			# it will switch limit_a and limit_b if limit_a > limit_b
			# it always fixates :begin
			def self.between(limit_a, limit_b)
				limit_a > limit_b ? new(limit_b, limit_a, false, :begin) : new(limit_a, limit_b, false, :begin)
			end
	
			# create a new interval that lasts from start_date until end_date
			# === Arguments
			# limit_a:: one of the two limiting datetimes
			# limit_b:: the other of the two limiting datetimes
			# fixated:: which end to fixate for operations. Defaults to :begin, valid values are:
			#  :begin:: The smaller datetime is fixated
			def initialize(limit_a, limit_b, fixed=nil)
				super(limit_a, limit_b, fixed)
				picoseconds       = @end.ps_number - @begin.ps_number if @begin.time?
				days, picoseconds = *picoseconds.divmod(PS_IN_DAY) if @begin.time?
				months            = 0
	
				if @begin.date? then
					a                 = Datetime.new(@begin.day_number, @begin.ps_number, ::Chronos::UTC)
					b                 = Datetime.new(@end.day_number,   @end.ps_number,   ::Chronos::UTC)
					days_after_months = days+b.day_of_month-a.day_of_month
					months            = b.year*12+b.month-a.year*12-a.month

					# move 1 month forward
					if days_after_months < 0 then
						days_after_months += a.days_in_month
						months            -= 1
					end

					days    += b.day_number - a.day_number
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
	
				@gregorian_duration = Duration::Gregorian.new(months, days+overflow, picoseconds, @language)
			end
			
			def to_gregorian_duration
				@gregorian_duration
			end
		end
	end
end
