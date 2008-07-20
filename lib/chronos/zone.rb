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
		Inspect = "#<%s:%s>"

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
			:'UTC-4:30'  => -16200,
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
			# for ::DateTime
			'-12:00'   => ['utc-12',   false],
			'-11:00'   => ['utc-11',   false],
			'-10:00'   => ['utc-10',   false],
			'-09:00'   => ['utc-9',    false],
			'-08:00'   => ['utc-8',    false],
			'-07:00'   => ['utc-7',    false],
			'-06:00'   => ['utc-6',    false],
			'-05:00'   => ['utc-5',    false],
			'-04:30'   => ['utc-4:30', false],
			'-04:00'   => ['utc-4',    false],
			'-03:00'   => ['utc-3',    false],
			'-03:30'   => ['utc-3:30', false],
			'-02:00'   => ['utc-2',    false],
			'-01:00'   => ['utc-1',    false],
			'+00:00'   => ['utc',      false],
			'+01:00'   => ['utc+1',    false],
			'+02:00'   => ['utc+2',    false],
			'+03:00'   => ['utc+3',    false],
			'+03:30'   => ['utc+3:30', false],
			'+04:00'   => ['utc+4',    false],
			'+05:00'   => ['utc+5',    false],
			'+05:30'   => ['utc+5:30', false],
			'+06:00'   => ['utc+6',    false],
			'+07:00'   => ['utc+7',    false],
			'+08:00'   => ['utc+8',    false],
			'+09:00'   => ['utc+9',    false],
			'+09:30'   => ['utc+9:30', false],
			'+10:00'   => ['utc+10',   false],
			'+11:00'   => ['utc+11',   false],
			'+12:00'   => ['utc+12',   false],
			# military & old
			'yankee'   => ['utc-12',   false],
			'xray'     => ['utc-11',   false],
			'hst'      => ['utc-10',   false],
			'whisky'   => ['utc-10',   false],
			'akst'     => ['utc-9',    false],
			'akdt'     => ['utc-9',    true],
			'ydt'      => ['utc-9',    true],
			'victor'   => ['utc-9',    false],
			'pst'      => ['utc-8',    false],
			'pdt'      => ['utc-8',    true],
			'uniform'  => ['utc-8',    false],
			'mst'      => ['utc-7',    false],
			'mdt'      => ['utc-7',    true],
			'tango'    => ['utc-7',    false],
			'cst'      => ['utc-6',    false],
			'cdt'      => ['utc-6',    true],
			'sierra'   => ['utc-6',    false],
			'est'      => ['utc-5',    false],
			'edt'      => ['utc-5',    true],
			'romeo'    => ['utc-5',    false],
			'vst'      => ['utc-4:30', false],
			'ast'      => ['utc-4',    false],
			'adt'      => ['utc-4',    true],
			'quebec'   => ['utc-4',    false],
			'nst'      => ['utc-3:30', false],
			'ndt'      => ['utc-3:30', true],
			'papa'     => ['utc-3',    false],
			'oscar'    => ['utc-2',    false],
			'november' => ['utc-1',    false],
			'gmt'      => ['utc',      false],
			'wet'      => ['utc',      false],
			'zulu'     => ['utc',      false],
			'cet'      => ['utc+1',    false],
			'cest'     => ['utc+1',    true],
			'alpha'    => ['utc+1',    false],
			'bravo'    => ['utc+2',    false],
			'msk'      => ['utc+3',    false],
			'charlie'  => ['utc+3',    false],
			'delta'    => ['utc+4',    false],
			'echo'     => ['utc+5',    false],
			'ist'      => ['utc+5:30', false],
			'foxtrot'  => ['utc+6',    false],
			'golf'     => ['utc+7',    false],
			'awst'     => ['utc+8',    false],
			'hotel'    => ['utc+8',    false],
			'india'    => ['utc+9',    false],
			'acst'     => ['utc+9:30', false],
			'aest'     => ['utc+10',   false],
			'kilo'     => ['utc+10',   false],
			'lima'     => ['utc+11',   false],
			'mike'     => ['utc+12',   false]
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
		
		def self.[](name)
			name = name.to_s.downcase
			if zone = @by_name[name] then
				zone
			elsif mapped = Map[name]
				@by_name[mapped.first]
			end
		end
		
		def zone_names
			@by_name.keys
		end
		
		def inspect
			sprintf Inspect, self.class, timezone_id
		end
	end
end
