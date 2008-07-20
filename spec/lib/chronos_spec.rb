unless $LOADED_FEATURES.include?('bacon_helper.rb')
	load(File.expand_path("#{__FILE__}/../../bacon_helper.rb"))
	$LOADED_FEATURES << 'bacon_helper.rb'
end

require 'time'
require 'date'
require 'chronos'

describe 'Chronos should provide localized strings' do
	before do
		Chronos.strings.keys.should.not.be.empty
	end

	it 'for monthnames' do
		Chronos.strings.keys.each { |language|
			12.times { |i|
				Chronos.string(language, :monthname, i).should.be.kind_of String
			}
		}
		# take 4 samples to verify that they aren't arbitrary strings
		Chronos.string('en_US', :monthname, 0).should.equal "january"
		Chronos.string('en_US', :monthname, 3).should.equal "april"
		Chronos.string('de_DE', :monthname, 0).should.equal "Januar"
		Chronos.string('de_DE', :monthname, 3).should.equal "April"
	end

	it 'for abbreviated monthnames' do
		Chronos.strings.keys.each { |language|
			12.times { |i|
				Chronos.string(language, :monthnameshort, i).should.be.kind_of String
			}
		}
		# take 4 samples to verify that they aren't arbitrary strings
		Chronos.string('en_US', :monthnameshort, 0).should.equal "jan"
		Chronos.string('en_US', :monthnameshort, 3).should.equal "apr"
		Chronos.string('de_DE', :monthnameshort, 0).should.equal "Jan"
		Chronos.string('de_DE', :monthnameshort, 3).should.equal "Apr"
	end

	it 'for daynames' do
		Chronos.strings.keys.each { |language|
			7.times { |i|
				Chronos.string(language, :dayname, i).should.be.kind_of String
			}
		}
		# take 4 samples to verify that they aren't arbitrary strings
		Chronos.string('en_US', :dayname, 0).should.equal "monday"
		Chronos.string('en_US', :dayname, 3).should.equal "thursday"
		Chronos.string('de_DE', :dayname, 0).should.equal "Montag"
		Chronos.string('de_DE', :dayname, 3).should.equal "Donnerstag"
	end

	it 'for abbreviated daynames' do
		Chronos.strings.keys.each { |language|
			7.times { |i|
				Chronos.string(language, :daynameshort, i).should.be.kind_of String
			}
		}
		# take 4 samples to verify that they aren't arbitrary strings
		Chronos.string('en_US', :daynameshort, 0).should.equal "mo"
		Chronos.string('en_US', :daynameshort, 3).should.equal "th"
		Chronos.string('de_DE', :daynameshort, 0).should.equal "Mo"
		Chronos.string('de_DE', :daynameshort, 3).should.equal "Do"
	end

	it 'for the units' do
		Chronos.strings.keys.each { |language|
			[:picosecond, :nanosecond, :microsecond, :millisecond, :second, :minute, :hour, :day, :week, :month, :year].each { |unit|
				3.times { |i|
					Chronos.string(language, unit, i).should.be.kind_of String
				}
			}
		}
		# take 4 samples to verify that they aren't arbitrary strings
		Chronos.string('en_US', :day,   1).should.equal "day"
		Chronos.string('en_US', :month, 3).should.equal "months"
		Chronos.string('de_DE', :day,   1).should.equal "Tag"
		Chronos.string('de_DE', :month, 3).should.equal "Monate"
	end
end

describe "Chronos should know timezones" do
	it "should return a default timezone with no further data given" do
		Chronos.timezone.should.be.kind_of Chronos::Zone
	end
	
	it "should raise if a specified timezone can't be normalized" do
		proc { Chronos.timezone('notmakingafrigginsense') }.should.raise ArgumentError
	end
end
