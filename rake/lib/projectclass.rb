#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# fix pre-rubygems 1.3 nuisance
begin
	require 'rubygems'
	module Kernel
		private :gem
		private :require
		private :open
	end
rescue LoadError; end

# FIXME: add a method_added hook to Object and Kernel to keep ProjectClass clean.

# This class is not written for long running scripts as it leaks symbols.
# It is openstructlike, but a bit more lightweight and blankslate so any method will work
# You can set values to procs and call __finalize__ to get them replaced by the value
# returned by the proc.
class ProjectClass
	names = public_instance_methods - %w[initialize inspect __id__ __send__]
	names.each { |m| undef_method m }

	attr_reader :__hash__
	
	def initialize(values=nil)
		@__hash__ = values || {}
	end
	
	def [](key)
		@__hash__[key.to_sym]
	end
	
	def []=(key,value)
		@__hash__[key.to_sym] = value
	end
	
	# All values that respond to .call are replaced by the value
	# returned when calling.
	def __finalize__
		@__hash__.each { |k,v|
			@__hash__[k] = v.call if v.respond_to?(:call)
		}
	end
	
	def method_missing(name, *args)
		case args.length
			when 0
				if key = name.to_s[/^(.*)\?$/, 1] then
					!!@__hash__[key.to_sym]
				else
					@__hash__[name]
				end
			when 1
				if key = name.to_s[/^(.*)=$/, 1] then
					@__hash__[key.to_sym] = args.first
				else
					super
				end
			else
				super
		end
	end
end
