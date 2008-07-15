#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This rakefile doesn't define any tasks, it is run after Rakefile has run and before
# any other imported rakefile, so it can clean up the Project object and resolve some
# dependencies.


# defaultize meta data, have to do this here because many tasks depend on Project.meta
# for initialization and task creation.
Project.meta.summary     ||= proc { extract_summary() }
Project.meta.description ||= proc { extract_description() || extract_summary() }
Project.meta.__finalize__
