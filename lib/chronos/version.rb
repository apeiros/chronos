#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



begin; require 'rubygems'; rescue LoadError; end



module Chronos
	version = '1.0.0'.freeze

	if Object.const_defined?(:Gem) && Gem.const_defined?(:Version) then
		VERSION = Gem::Version.new(version)
	else
		VERSION = version
	end
end
