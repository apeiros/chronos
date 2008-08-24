#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos

	# An immutable class representing the amount of intervening time in a time interval.
	# A duration has no start- nor end-point.
	# Also see Interval
	class Duration
		FormatToS     = "%dps (%s)".freeze
		FormatInspect = "#<%s:0x%08x %dps (%s)>".freeze

		def self.with(parts)
			new(
				parts[:days] || parts[:d] || 0,
				parts[:picoseconds] || parts[:ps] || 0,
				parts[:language]
			)
		end
		
		def self.import(duration)
			duration.to_duration
		end

		attr_reader :days
		attr_reader :picoseconds
		attr_reader :language
		
		# Create a Duration of given picoseconds length
		def initialize(days, picoseconds, language=nil)
			@days        = days
			@picoseconds = picoseconds
			@language    = Chronos.language(language)
		end

		def +@
			self
		end

		def -@
			self.class.new(*(self.to_a(true).map { |e| -e }+[@language]))
		end

		def +(other)
			self.class.new(*(self.to_a(true).zip(other.to_a).map { |a,b| a+b }+[@language]))
		end
		
		def -(other)
			self.class.new(*(self.to_a(true).zip(other.to_a).map { |a,b| a-b }+[@language]))
		end

		def *(other)
			self.class.new(*(self.to_a(true).map { |e| e*other }+[@language]))
		end

		def /(other)
			self.class.new(*(self.to_a(true).map { |e| e/other }+[@language]))
		end

		def div(other)
			self.class.new(*(self.to_a(true).map { |e| e.div(other) }+[@language]))
		end
		
		def quo(other)
			self.class.new(*(self.to_a(true).map { |e| e.quo(other) }+[@language]))
		end
		
		def %(other)
			raise "Not yet implemented"
			# Duration % Duration -> modulo per unit, e.g. duration % 1.hour -> ps % (1*PS_IN_HOUR)
			# Duration % Symbol -> shortcut, e.g. duration % :hour -> duration % 1.hour
		end
		
		# Split the duration into durations with each only one of the atomic units set
		def split
			lang  = [@language]
			klass = self.class
			ary   = to_a(true)
			(0...(ary.size)).zip(ary).map { |i,e|
				init = Array.new(ary.size, 0)+lang
				init[i] = e
				klass.new(*init)
			}
		end
		
		# An array with the atomic units and the language of this Duration
		def to_a(exclude_language=nil)
			exclude_language ? [@days, @picoseconds] : [@days, @picoseconds, @language]
		end
		
		def to_hash
			{
				:days        => @days,
				:d           => @days,
				:ps          => @picoseconds,
				:picoseconds => @picoseconds,
				:language    => @language,
			}
		end
		
		def to_duration
			self
		end
		
		def values_at(*keys)
			to_hash.values_at(*keys)
		end
		
		def durations_at(*keys)
			keys.zip(values_at(*keys)).map { |key, value|
				self.class.with(key => value, :language => @language)
			}
		end

		# return a readable representation
		def to_s
			sprintf(self.class::FormatToS, *self)
		end

		def inspect # :nodoc:
			sprintf(self.class::FormatInspect, self.class, object_id<<1, *self)
		end
	end
end
