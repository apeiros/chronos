#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



namespace :spec do
	desc 'Run all specs with basic output'
	task :run do
		dependency(%w'bacon flexmock', 'Requires %s to run')

		Bacon.extend Bacon.const_get('TestUnitOutput') rescue abort "No such formatter: #{output}"
		Bacon.summary_on_exit
		
		Dir.glob("spec/**/*_spec.rb") { |file|
			load file
		}
	end

	desc 'Run all specs with text output'
	task :specdoc do |t|
		raise "Not implemented"
	end

	optional_task(:rcov, 'Spec::Rake::SpecTask') do
		desc 'Run all specs with RCov'
		Spec::Rake::SpecTask.new(:rcov) do |t|
			t.ruby_opts   = Project.rcov.ruby_opts
			t.spec_opts   = Project.rcov.opts
			t.spec_files  = Project.rcov.files
			t.libs        = Project.rcov.libs || []
			t.rcov        = true
			t.rcov_dir    = Project.rcov.dir
			t.rcov_opts   = Project.rcov.opts
		end
	end
	
	optional_task(:verify, 'Rcov::VerifyTask') do
		Rcov::VerifyTask.new(:verify) do |t| 
			t.threshold = Project.rcov.threshold
			t.index_html = File.join(Project.rcov.dir, 'index.html')
			t.require_exact_threshold = Project.rcov.threshold_exact
		end

		task :verify => :rcov
	end

end  # namespace :spec

desc 'Alias to spec:run'
task :spec => 'spec:run'

task :clobber => 'spec:clobber'
