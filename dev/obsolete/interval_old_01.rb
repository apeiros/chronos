# def ld;%w{datetime duration interval}.each{|f|load "chronos/#{f}.rb"};end
require 'rational'

module Chronos
	# An Interval is determinated by a start and an end Datetime.
	# Unlike in Duration, this allows to determine the months part exactly in
	# seconds (and therefore minutes, hours, days, weeks).
	# That opens up the possibility to say how
	class Interval < Duration
		attr_reader :start, :end
		
		# unlike new, between doesn't care about what date is before the other,
		# it will switch them if date1 > date2
		def self.between(date1, date2)
			date1 > date2 ? new(date2, date1) : new(date1, date2)
		end

		# create a new interval that lasts from start_date until end_date
		def initialize(start_date, end_date)
			raise ArgumentError, "start after end" if start_date > end_date
			@start = start_date
			@end   = end_date

			if start_date.datetime? && end_date.datetime? then
				tmp1       = Datetime.new(@start.day_number,nil,nil)
				tmp2       = Datetime.new(@end.day_number,nil,nil)
				days       = tmp2.day_of_month - tmp1.day_of_month
				over, secs = (@end.second_number-@start.second_number).divmod(86400)
				days      += over
				if days < 0 then
					tmp2 = Datetime.new(@end.day_number+days)
					days = -days
				end
				months  = tmp2.month - tmp1.month
				months += (tmp2.year - tmp1.year)*12
				seconds = (@end.day_number-@start.day_number)*86400
			elsif start_date.no_time? && end_date.no_time? then
				tmp1    = Datetime.new(@start.day_number,nil,nil)
				tmp2    = Datetime.new(@end.day_number,nil,nil)
				days    = tmp2.day_of_month - tmp1.day_of_month
				if days < 0 then
					tmp2 = Datetime.new(@end.day_number+days)
					days = -days
				end
				months  = tmp2.month - tmp1.month
				months += (tmp2.year - tmp1.year)*12
				seconds = (@end.day_number-@start.day_number)*86400
			elsif start_date.no_date? && end_date.no_date? then
				months  = 0
				seconds = (tmp3.second_number-tmp2.second_number)+(tmp3.fraction-tmp2.fraction)
			else
				raise ArgumentError, "Invalid dates for interval"
			end
			
			@seconds = seconds
			@months  = months
		end
		
		def inspect
			"<Interval #{@start} - #{@end}, @months=#{@months}, @seconds=#{@seconds}>"
		end
		
		def days_after_months(modify=0)
			years, months = @months.divmod(12)
			month = @start.month + months
			overflow, month = (month-1+modify).divmod(12)
			month += 1
			year  = @start.year + years + overflow
			day   = [@start.day_of_month, Datetime.days_in_month(month, year)].min
			tmp   = Datetime.civil(year, month, day)
			(@end.day_number - tmp.day_number)
		end
		
		# example:
		#   birthsday = Chronos::Datetime.civil(year, month, day)
		#   interval  = Chronos::Datetime.today - birthsday
		#   puts "Days since your last birthsday: #{interval.days_after_years.floor}"
		#   puts "Days to your next birthsday: #{interval.days_after_years(1).abs.floor}"
		def days_after_years(modify=0)
			years = @months.div(12)
			year  = @start.year + years + modify
			day   = [@start.day_of_month, Datetime.days_in_month(@start.month, year)].min
			tmp   = Datetime.civil(year, @start.month, day)
			(@end.day_number - tmp.day_number)
		end
		
		# [...] sequences may include a single replacement. if that replacement is 0, the whole segment is omitted
		# [...>] sequences work the same, but are not omitted if there are optional replacements on the right side that haven't been omitted
		def format(string="[%{full_years} years >][%{months_after_years} months >][%{days_after_months} days >][%{hours_after_days}h>]%{minutes_after_hours}m>]%{seconds_after_minutes}s")
			
		end
	end
end