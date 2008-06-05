tried = false
begin
	require 'test/unit'
	require 'chronos'
rescue LoadError
	raise if tried
	$:.unshift(File.expand_path(File.dirname(__FILE__)+'/../lib'))
	tried = true
	retry
end

class TestChronos < Test::Unit::TestCase
end

