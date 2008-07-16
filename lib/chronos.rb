#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



class Time; end
class Date; end
class DateTime < Date; end



require 'chronos/datetime'
require 'chronos/duration'
require 'chronos/exceptions'
require 'chronos/interval'
require 'chronos/strings'
require 'chronos/zone'
require 'yaml'



module Chronos
	YAMLExt           = '.yaml'.freeze
	ZonesFile         = File.join(File.dirname(__FILE__), "chronos", "data", "zones.tab").freeze
	ZonesData         = File.join(File.dirname(__FILE__), "chronos", "data", "zones.marshal").freeze
	DefaultizeStrings = [
		:picosecond,
		:nanosecond,
		:microsecond,
		:millisecond,
		:second,
		:minute,
		:hour,
		:day,
		:month,
		:year
	].freeze
		
	@strings = {}

	class <<self
		attr_reader :language
		attr_reader :timezone
		attr_reader :calendar
		
		def string(lang, key, quantity=nil)
			if quantity then
				@strings[lang][key][quantity]
			else
				@strings[lang][key]
			end
		end

		# Load a yaml strings file
		def load_strings(strfile, language)
			data = YAML.load_file(name)
			Defaultize.each do |key|
				data[key] = Hash.new(data[key].delete(nil)).merge(data[key])
			end
			@strings[language] ||= {}
			@strings[language].update(data)
		end

		# Normalize the language to something Chronos can work with (or raise)
		def normalize_language(val) # :nodoc:
			raise ArgumentError, "Invalid language #{val.inspect}" unless lang = val[/^[a-z]{2}_[A-Z]{2}/]
			lang
		end
		
		# Normalize the timezone to something Chronos can work with (or raise)
		def normalize_timezone(val) # :nodoc:
			val.upcase
		end
		
		# Set the default language to use with Chronos classes (parsing/printing)
		def language=(value)
			@language = normalize_language(value).dup.freeze
		end

		# Set the default timezone to use with Chronos classes
		def timezone=(value)
			@language = normalize_timezone(value).dup.freeze
		end
		
		# Set the calendar system Chronos should use. You can also just require
		# the appropriate file, e.g.:
		#   require 'chronos/gregorian'
		# will call Chronos.use :Gregorian
		def use(calendar_system)
			raise "Calendar system is already set" if @calendar
			raise TypeError, "Symbol expected, #{calendar_system.class} given" unless calendar_system.kind_of?(Symbol)
			@calendar = calendar_system
		end
	end

	self.language = ENV['LANG'] || 'en_US'
	self.timezone = Time.now.strftime("%Z")
	@calendar     = nil
	
	Zone.load(ZonesFile, ZonesData, false)
	Dir.glob("#{File.dirname(__FILE__)}/chronos/locale/strings/*.yaml") { |file|
		lang = File.basename(file, YAMLExt)
		load_strings(file, lang)
	}
end
