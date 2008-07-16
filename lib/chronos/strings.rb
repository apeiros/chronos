#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'chronos'



module Chronos


	class Strings
		Defaultize = [:month, :day]
		def initialize
			@strings = YAML.load_file(name)
			Defaultize.each do |key|
				@strings[key] = Hash.new(@strings[key].delete(nil)).merge(@strings[key])
			end
		end
	end
end
