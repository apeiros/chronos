module Chronos
end

require 'chronos/datetime'
require 'chronos/duration'
require 'chronos/exceptions'
require 'chronos/interval'
require 'chronos/zone'

# run test suite
load(File.dirname(__FILE__)+"/../test/tc_"+File.basename(__FILE__)) if __FILE__ == $0
