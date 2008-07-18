#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This file is just a shortcut to require all relevent files
# for gregorian and setting Chronos to use the gregorian classes
# per default.



require 'chronos'
require 'chronos/datetime/gregorian'
require 'chronos/duration/gregorian'
require 'chronos/interval/gregorian'



Chronos.use :Gregorian
Datetime = Chronos::Datetime::Gregorian
Duration = Chronos::Duration::Gregorian
Interval = Chronos::Interval::Gregorian
Calendar = Chronos::Calendar::Gregorian
