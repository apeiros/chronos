unless $LOADED_FEATURES.include?('bacon_helper.rb')
	load '../bacon_helper.rb'
	$LOADED_FEATURES << 'bacon_helper.rb'
end

require 'time'
require 'date'
require 'chronos'

describe 'Chronos' do
	it 'Should provide localized strings for monthnames' do
		Chronos.strings.keys.should.not.be.empty
		Chronos.strings.keys.each { |language|
			12.times { |i|
				Chronos.string(language, :monthname, i).should.be.kind_of String
			}
		}
	end

	it 'Should provide localized strings for daynames' do
		Chronos.strings.keys.should.not.be.empty
		Chronos.strings.keys.each { |language|
			12.times { |i|
				Chronos.string(language, :dayname, i).should.be.kind_of String
			}
		}
	end
end
