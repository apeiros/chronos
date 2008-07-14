$LOAD_PATH.unshift(File.expand_path(__FILE__+'../../../lib'))

#p $LOAD_PATH

require 'benchmark'
require 'chronos/datetime'
require 'date'

include Chronos

N1 = 10_000

Benchmark.bm(30) { |x|
	x.report('create:Time')     { N1.times { Time.mktime(2008,7,1) } }
	x.report('create:DateTime') { N1.times { DateTime.new(2008,7,1) } }
	x.report('create:Chronos')  { N1.times { Datetime.civil(2008,7,1) } }

	t = Time.mktime(2008,7,1)
	d = DateTime.new(2008,7,1)
	c = Datetime.civil(2008,7,1)
	x.report('strftime:Time')     { N1.times { t.strftime("%Y-%m-%d") } }
	x.report('strftime:DateTime') { N1.times { d.strftime("%Y-%m-%d") } }
	x.report('strftime:Chronos')  { N1.times { c.format("%Y-%m-%d") } }
}
