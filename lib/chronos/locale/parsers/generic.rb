add_format_as "Y", /(\d{4})/,                :year         # 4 digits
add_format_as "m", /(0?[1-9]|1[012])/,       :month        # 1-12 with optional leading zero
add_format_as "d", /(0?[1-9]|[12]\d|3[01])/, :day_of_month # 1-31 with optional leading zero
add_format_as "H", /([01]?\d|2[123])/,       :hour         # 0-23 with optional leading zero
add_format_as "M", /([0-5]?\d)/,             :minute       # 0-59 with optional leading zero
add_format_as "S", /([0-5]?\d|60)/,          :second       # 0-60 with optional leading zero (leap second)
add_format_as "Z", /(#{Chronos::TimezonesByName.keys.sort.join('|')})/, :timezone do |parser, matches| # timezones are known to have no special chars, no escaping required
	if tz = Chronos::TimezonesByName[matches.first] then
		tz.offset
	end
end
add_format_as "z", /(+-)/, :timezone do |parser, matches| # timezones are known to have no special chars, no escaping required
	if tz = Chronos::TimezonesByName[matches.first] then
		tz.offset
	end
end

add_format_as "iso_date", /#{Y}-(#{m})-#{d}/, :year, :month, :day
add_format_as 

add_format(/#{iso_date}/)
