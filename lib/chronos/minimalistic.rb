#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos/datetime'




module Chronos
	module Datetime
		module Gregorian

			# require 'chronos/minimalistic' for 'y' method.
			alias y year

			# require 'chronos/minimalistic' for 'm' method.
			alias m month

			# require 'chronos/minimalistic' for 'd' method.
			alias d day_of_month

			# require 'chronos/minimalistic' for 'H' method.
			alias H hour

			# require 'chronos/minimalistic' for 'M' method.
			alias M minute

			# require 'chronos/minimalistic' for 'S' method.
			alias S s
		end
	end
end
