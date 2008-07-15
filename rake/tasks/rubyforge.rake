namespace :gem do
	# Empty tasks for missing prerequisites.
	if !lib?(%w'rubyforge rake/contrib/sshpublisher') then
		task :missing_prerequisites do
			'This task requires rubyforge and/or rake/contrib/sshpublisher to run.'
		end

		task :release         => :missing_prerequisites
		task :release_notes   => :missing_prerequisites
		task :release_changes => :missing_prerequisites
		task :preformatted    => :missing_prerequisites

	# Real tasks if prerequisites are met.
	else
		Project.rubyforge.name        ||= Project.meta.name
		Project.rubyforge.description ||= Project.meta.description
		Project.rubyforge.changes     ||= Project.meta.changes
		Project.rubyforge.version       = Project.meta.version

		desc 'Package and upload to RubyForge'
		task :release => [:clobber, 'gem:package'] do |t|
			v = ENV['VERSION'] or abort 'Must supply VERSION=x.y.z'
			abort "Versions don't match #{v} vs #{PROJ.version}" if v != Project.meta.version.to_s
			pkg = "pkg/#{Project.gem.spec.full_name}"
	
			if $DEBUG then
				puts "release_id = rf.add_release #{Project.rubyforge.name.inspect}, #{Project.rubyforge.name.inspect}, #{Project.rubyforge.version.inspect}, \"#{pkg}.tgz\""
				puts "rf.add_file #{Project.rubyforge.name.inspect}, #{Project.meta.name.inspect}, release_id, \"#{pkg}.gem\""
			end
	
			rf = RubyForge.new
			puts 'Logging in'
			rf.login
	
			c = rf.userconfig
			c['release_notes']   = Project.rubyforge.description if Project.rubyforge.description
			c['release_changes'] = Project.rubyforge.changes if Project.rubyforge.changes
			c['preformatted']    = true
	
			files = [(Project.gem.need_tar ? "#{pkg}.tgz" : nil),
							 (Project.gem.need_zip ? "#{pkg}.zip" : nil),
							 "#{pkg}.gem"].compact
	
			puts "Releasing #{Project.rubyforge.name} v. #{Project.rubyforge.version}"
			rf.add_release Project.rubyforge.name, Project.meta.name, Project.rubyforge.version, *files
		end
	end
end  # namespace :gem


namespace :doc do
	if !lib?(%w'rubyforge rake/contrib/sshpublisher') then
	  desc "Publish RDoc to RubyForge"
		task :release => 'rubyforge:missing_prerequisite'
	else
		desc "Publish RDoc to RubyForge"
		task :release => %w(doc:clobber_rdoc doc:rdoc) do
			config      = YAML.load_file(File.expand_path('~/.rubyforge/user-config.yml'))
			host        = "#{config['username']}@rubyforge.org"
			remote_dir  = "/var/www/gforge-projects/#{Project.rubyforge.name}/"
			remote_dir << Project.rdoc.remote_dir if Project.rdoc.remote_dir
			local_dir   = Project.rdoc.dir
	
			Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
		end
	end
end  # namespace :doc
