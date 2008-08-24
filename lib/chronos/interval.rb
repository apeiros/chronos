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
		ValidFixed        = [:begin, :end].freeze
		InspectFixedBegin = "<%p [%p] - %p, %p>".freeze
		InspectFixedEnd   = "<%p %p - [%p], %p>".freeze

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
			@fixed = fixed || :begin
			raise ArgumentError, "limites don't have the same signature" unless (limit_a.time? == limit_b.time? && limit_a.date? == limit_b.date?)
			raise ArgumentError, "invalid fixed, must be :begin or :end" unless ValidFixed.include?(@fixed)

			@language = limit_a.language

			if limit_a > limit_b then
				@begin    = limit_b
				@end      = limit_a
				@negative = false
			else
				@begin    = limit_a
				@end      = limit_b
				@negative = true
			end

			overflow    = 0
			picoseconds = @end.ps_number  - @begin.ps_number  if @begin.time?
			days        = @end.day_number - @begin.day_number if @begin.date?
			overflow, picoseconds = *picoseconds.divmod(PS_IN_DAY) if @begin.time?
			@duration = Duration.new(days+overflow, picoseconds, @language)
		end

		# Returns the same Interval but with begin as fixpoint for operations
		def fixed_begin
			self.class.new(@begin, @end, :begin)
		end

		# Returns the same interval but with end as fixpoint for operations
		def fixed_end
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

		# The number of picoseconds
		def picoseconds
			@duration.picoseconds
		end
		
		def days
			@duration.days
		end
		
		def values_at(*keys)
			to_hash.values_at(*keys)
		end

		# converts this interval to a duration
		# if you set as_seconds to true it will convert the
		# month primitive to seconds and use that
		def to_duration
			@duration
		end

		def to_hash
			@duration.to_hash.merge(:begin => @begin, :end => @end, :language => @language)
		end

		def format(string)
			raise NoMethodError
		end

		def inspect
			if @fixed == :begin then
				sprintf InspectFixedBegin, self.class, @begin, @end, @duration
			else
				sprintf InspectFixedEnd, self.class, @begin, @end, @duration
			end
		end
	end
end
