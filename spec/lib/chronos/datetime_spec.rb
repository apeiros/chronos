unless $LOADED_FEATURES.include?('bacon_helper.rb')
	load '../../bacon_helper.rb'
	$LOADED_FEATURES << 'bacon_helper.rb'
end

require 'time'
require 'date'

describe 'Chronos::Datetime' do
	it '::today should create an instance representing current date' do
		proc { Chronos::Datetime.today }.should.not.raise
	end

	it '::now should create an instance representing current date and time' do
		proc { Chronos::Datetime.now }.should.not.raise
	end

	it 'should import Datetime instances' do
		proc { Chronos::Datetime.import(Datetime.now) }.should.not.raise
	end

	it 'should import Time instances' do
		proc { Chronos::Datetime.import(Time.now) }.should.not.raise
	end

	it 'should import Date instances' do
		proc { Chronos::Datetime.import(Date.today) }.should.not.raise
	end

	it 'should import DateTime instances' do
		proc { Chronos::Datetime.import(DateTime.now) }.should.not.raise
	end
end
