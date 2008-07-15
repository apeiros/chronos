#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'
require 'enumerator'



class Duration
	ToTextEn = {
		-(1/0.0) => proc { |s| sprintf "%d weeks ago", -s.div(604800) },
		-1209600 => proc { |s| "one week ago" },
		-604800 => proc { |s| sprintf "%d days ago", -s.div(86500) },
		-172800 => proc { |s| "yesterday" },
		0 => proc { |s| "today" },
		86400 => proc { |s| "tomorrow" },
		172800 => proc { |s| sprintf "in %d days", (s/86400).ceil },
		604800 => proc { |s| "in one week" },
		1209600 => proc { |s| sprintf "in %d weeks", (s/604800).ceil },
	}.to_a.sort

	def initialize(seconds, months=0)
		@seconds = seconds
		@months  = months
	end
	
	def to_text
		ToTextEn.each_cons(2) { |(v,t), (v2,t2)|
			return t.call(@seconds) if @seconds >= v && @seconds < v2
		}
		ToTextEn.last.last.call(@seconds)
	end
	alias to_s to_text
end

time = Time.today-2*7*24*3600
30.times { puts "#{time.strftime('%Y-%m-%d')}: #{Duration.new(time-Time.today)}"; time+=86400 }
