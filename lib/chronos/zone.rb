#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Chronos
	Zone = Struct.new(
		:timezone_id,
		:language,
		:utc,
		:offset,
		:dstrule,
		:numeric,
		:alpha2,
		:alpha3,
		:country,
		:latitude,
		:longitude,
		:latitude_iso,
		:longitude_iso
	)
	class Zone
		@by_name   = {}
		@by_region = {}

		# the UTC timezones, offset in seconds
		Offset	= {
			:'UTC-12'    => -43200,
			:'UTC-11'    => -39600,
			:'UTC-10'    => -36000,
			:'UTC-9:30'  => -34200,
			:'UTC-9'     => -32400,
			:'UTC-8'     => -28800,
			:'UTC-7'     => -25200,
			:'UTC-6'     => -21600,
			:'UTC-5'     => -18000,
			:'UTC-4'     => -14400,
			:'UTC-3:30'  => -12600,
			:'UTC-3'     => -10800,
			:'UTC-2'     =>  -7200,
			:'UTC-1'     =>  -3600,
			:'UTC'       =>      0,
			:'UTC+1'     =>   3600,
			:'UTC+2'     =>   7200,
			:'UTC+3'     =>  10800,
			:'UTC+3:07'  =>  11224,
			:'UTC+3:30'  =>  12600,
			:'UTC+4'     =>  14400,
			:'UTC+4:30'  =>  16200,
			:'UTC+5'     =>  18000,
			:'UTC+5:30'  =>  19800,
			:'UTC+5:45'  =>  20700,
			:'UTC+6'     =>  21600,
			:'UTC+6:30'  =>  23400,
			:'UTC+7'     =>  25200,
			:'UTC+8'     =>  28800,
			:'UTC+8:45'  =>  31500,
			:'UTC+9'     =>  32400,
			:'UTC+9:30'  =>  34200,
			:'UTC+10'    =>  36000,
			:'UTC+10:30' =>  37800,
			:'UTC+11'    =>  39600,
			:'UTC+11:30' =>  41400,
			:'UTC+12'    =>  43200,
			:'UTC+12:45' =>  45900,
			:'UTC+13'    =>  46800,
			:'UTC+14'    =>  50400,
		}

		# map old/military timezone names to UTC
		# corresponding utc, isDST[BOOL]
		Map	= Hash.new { |hash, key| key }.merge!({
			'YANKEE'   => [:'UTC-12',   false],
			'XRAY'     => [:'UTC-11',   false],
			'HST'      => [:'UTC-10',   false],
			'WHISKY'   => [:'UTC-10',   false],
			'AKST'     => [:'UTC-9',    false],
			'AKDT'     => [:'UTC-9',    true],
			'YDT'      => [:'UTC-9',    true],
			'VICTOR'   => [:'UTC-9',    false],
			'PST'      => [:'UTC-8',    false],
			'PDT'      => [:'UTC-8',    true],
			'UNIFORM'  => [:'UTC-8',    false],
			'MST'      => [:'UTC-7',    false],
			'MDT'      => [:'UTC-7',    true],
			'TANGO'    => [:'UTC-7',    false],
			'CST'      => [:'UTC-6',    false],
			'CDT'      => [:'UTC-6',    true],
			'SIERRA'   => [:'UTC-6',    false],
			'EST'      => [:'UTC-5',    false],
			'EDT'      => [:'UTC-5',    true],
			'ROMEO'    => [:'UTC-5',    false],
			'AST'      => [:'UTC-4',    false],
			'ADT'      => [:'UTC-4',    true],
			'QUEBEC'   => [:'UTC-4',    false],
			'NST'      => [:'UTC-3:30', false],
			'NDT'      => [:'UTC-3:30', true],
			'PAPA'     => [:'UTC-3',    false],
			'OSCAR'    => [:'UTC-2',    false],
			'NOVEMBER' => [:'UTC-1',    false],
			'GMT'      => [:'UTC',      false],
			'WET'      => [:'UTC',      false],
			'ZULU'     => [:'UTC',      false],
			'CET'      => [:'UTC+1',    false],
			'CEST'     => [:'UTC+1',    true],
			'ALPHA'    => [:'UTC+1',    false],
			'BRAVO'    => [:'UTC+2',    false],
			'MSK'      => [:'UTC+3',    false],
			'CHARLIE'  => [:'UTC+3',    false],
			'DELTA'    => [:'UTC+4',    false],
			'ECHO'     => [:'UTC+5',    false],
			'IST'      => [:'UTC+5:30', false],
			'FOXTROT'  => [:'UTC+6',    false],
			'GOLF'     => [:'UTC+7',    false],
			'AWST'     => [:'UTC+8',    false],
			'HOTEL'    => [:'UTC+8',    false],
			'INDIA'    => [:'UTC+9',    false],
			'ACST'     => [:'UTC+9:30', false],
			'AEST'     => [:'UTC+10',   false],
			'KILO'     => [:'UTC+10',   false],
			'LIMA'     => [:'UTC+11',   false],
			'MIKE'     => [:'UTC+12',   false]
		})
		
		# load locations from a tabfile
		def self.load(tabfile, marshalfile=nil, marshal=true)
			if marshalfile && File.readable?(marshalfile) && File.mtime(tabfile) <= File.mtime(marshalfile) then
				@by_name.update(Marshal.load(File.read(marshalfile)))
			else
				data = {}
				File.foreach(tabfile) { |line|
					next if line[0] == ?#
					tmp                    = line.chomp.split("\t")
					tmp[3,0]               = 0
					location               = new(*tmp)
					location.utc           = location.utc.to_sym
					location.offset        = Offset[location.utc]
					location.numeric       = Integer(location.numeric) rescue nil
					location.latitude      = Float(location.latitude) rescue nil
					location.longitude     = Float(location.longitude) rescue nil
					location.latitude_iso  = Integer(location.latitude_iso) rescue nil
					location.longitude_iso = Integer(location.longitude_iso) rescue nil
					data[location.timezone_id.downcase] = location
				}
				@by_name.update(data)
				if marshalfile && marshal then
					File.open(marshalfile, "wb") { |fh|
						fh.write(Marshal.dump(data))
					}
				end
			end
		end
		
		def self.[](by_name)
			@by_name[by_name.downcase]
		end
	end
end
