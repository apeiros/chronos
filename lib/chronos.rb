#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



class Time; end
class Date; end
class DateTime < Date; end



require 'chronos/calendar'
require 'chronos/datetime'
require 'chronos/duration'
require 'chronos/exceptions'
require 'chronos/interval'
require 'chronos/ruby'
require 'chronos/zone'
require 'yaml'



# == Summary
# 
# == Synopsis
#
# == Description
#
# == Duck typing
# All chronos classes will accept in places of
# Datetime:: objects that respond to to_datetime (careful as this collides with date's Time#to_datetime, you have to explicitly import them)
# Duration:: objects that respond to to_duration
# Interval:: objects that respond to to_interval
# Calendar:: objects that respond to to_calendar
#
# For classes that don't have those methods you can try Klassname::import.
# For example
#   Chronos::Datetime.import(Time.now) # => Chronos::Datetime
#
module Chronos
	# picoseconds in a nanosecond
	PS_IN_NANOSECOND  = 1_000

	# picoseconds in a microsecond
	PS_IN_MICROSECOND = PS_IN_NANOSECOND * 1_000

	# picoseconds in a microsecond
	PS_IN_MILLISECOND = PS_IN_MICROSECOND * 1_000

	# picoseconds in a second
	PS_IN_SECOND      = PS_IN_MILLISECOND * 1_000
	
	# picoseconds in a minute
	PS_IN_MINUTE      = PS_IN_SECOND * 60

	# picoseconds in an hour
	PS_IN_HOUR        = PS_IN_MINUTE * 60

	# picoseconds in a day
	PS_IN_DAY         = PS_IN_HOUR * 24

	# picoseconds in a week
	PS_IN_WEEK         = PS_IN_DAY * 7

	# The extension YAML files use
	YAMLExt           = '.yaml'.freeze
	
	# The full path of the zones.tab file
	ZonesFile         = File.join(File.dirname(__FILE__), "chronos", "data", "zones.tab").freeze
	
	# The full path of the marshalled zones data cache file
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
		:week,
		:month,
		:year
	].freeze
	
	class LocalizationError < RuntimeError; end
	
	@strings = {}

	class <<self
		attr_reader :calendar
		attr_reader :strings
		
		# TODO: refactor this ugly piece of code
		def string(lang, key, quantity=nil)
			if localized1 = @strings[lang] then
				if localized2 = localized1[key] then
					quantity ? localized2[quantity] : localized2
				elsif lang != 'en_US' && localized1 = @strings['en_US'] then
					if localized2 = localized1[key] then
						warn "Couldn't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}, falling back to en_US"
						quantity ? localized2[quantity] : localized2
					else
						raise LocalizationError, "Can't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}"
					end
				else
					raise LocalizationError, "Can't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}"
				end
			elsif lang != 'en_US' && localized1 = @strings['en_US'] then
				if localized2 = localized1[key] then
					warn "Couldn't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}, falling back to en_US"
					quantity ? localized2[quantity] : localized2
				else
					raise LocalizationError, "Can't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}"
				end
			else
				raise LocalizationError, "Can't localize #{key.inspect} for #{lang} with quantity #{quantity.inspect}"
			end
		end

		# Load a yaml strings file
		def load_strings(strfile, language)
			data = YAML.load_file(strfile)
			DefaultizeStrings.each do |key|
				data[key] = Hash.new(data[key].delete(nil)).merge(data[key])
			end
			@strings[language] ||= {}
			@strings[language].update(data)
		end

		# Normalize the language to something Chronos can work with (or raise)
		def normalize_language(val) # :nodoc:
			raise ArgumentError, "Invalid language #{val.inspect}" unless lang = val[/^[a-z]{2}_[A-Z]{2}/]
			unless @strings.has_key?(language) then
				warn "Language #{lang} not available, falling back to en_US"
				'en_US'
			else
				lang
			end
		end
		
		# Normalize the timezone to something Chronos can work with (or raise)
		def normalize_timezone(val) # :nodoc:
			raise ArgumentError, "Could not normalize timezone #{val.inspect}" unless zone = Zone[val]
			zone
		end
		
		# Set the default language to use with Chronos classes (parsing/printing)
		def language=(value)
			@language = normalize_language(value)
		end

		# Set the default timezone to use with Chronos classes
		def timezone=(value)
			@timezone = normalize_timezone(value)
		end
		def timezone(tz=nil)
			case tz
				when Chronos::Zone
					tz
				when NilClass
					@timezone
				else
					normalize_timezone(tz)
			end
		end
		
		def language(lang=nil)
			case lang
				when NilClass
					@language
				else
					normalize_language(lang)
			end
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
	
	Zone.load(ZonesFile, ZonesData, false)
	Dir.glob("#{File.dirname(__FILE__)}/chronos/locale/strings/*.yaml") { |file|
		lang = File.basename(file, YAMLExt)
		begin
			load_strings(file, lang)
		rescue => e
			warn "Had errors while loading strings file #{file}: #{e}"
		end
	}

	self.language = ENV['LANG'] || 'en_US'
	self.timezone = Time.now.strftime("%Z")
	@calendar     = nil
end
