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
		def self.with(parts, lang)
			new(parts[:picoseconds] || parts[:ps] || 0)
		end
		
		attr_reader :picoseconds
		attr_reader :language
		
		# Create a Duration of given picoseconds length
		def initialize(picoseconds, language=nil)
			@picoseconds = picoseconds
			@language    = Chronos.language(language)
		end

		def +@
			dup
		end
		
		def -@
			self.class.new(*self.to_a.map { |e| -e })
		end

		def +(other)
			self.class.new(*self.to_a.zip(other.to_a).map { |a,b| a+b })
		end
		
		def -(other)
			self.class.new(*self.to_a.zip(other.to_a).map { |a,b| a-b })
		end

		def *(other)
			self.class.new(*self.to_a.map { |e| e*other })
		end

		def /(other)
			self.class.new(*self.to_a.map { |e| e/other })
		end

		def div(other)
			self.class.new(*self.to_a.map { |e| e.div(other) })
		end
		
		def quo(other)
			self.class.new(*self.to_a.map { |e| e.quo(other) })
		end
		
		def in_picoseconds
			@picoseconds
		end
		
		def to_a
			[@picoseconds, @language]
		end
		
		def to_hash
			{:ps => @picoseconds, :picoseconds => @picoseconds}
		end
		
		def values_at(*keys)
			to_hash.values_at(*keys)
		end

		# return a readable representation
		def to_s
			sprintf(FormatToS, *self)
		end

		def inspect # :nodoc:
			sprintf(FormatInspect, self.class, object_id<<1, *self)
		end
	end
end
