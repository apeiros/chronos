#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'stringio'
require 'ostruct'



# fix pre-rubygems 1.3 nuisance
begin
	require 'rubygems'
	module Kernel
		private :gem
		private :require
		private :open
	end
rescue LoadError; end

# needed for has_version?
class Array
	include Comparable
end

# The module BoneSplitter offers various helpful methods for rake tasks.
#
module BoneSplitter
	def self.find_executable(*names)
		path = ENV["PATH"].split(File::PATH_SEPARATOR)
		names.each { |name|
			found = path.map { |path| File.join(path, name) }.find { |e| File.executable?(e) }
			return found if found
		}
		nil
	end
		
	@libs = {}
	@bin = OpenStruct.new(
		:diff => find_executable('diff', 'gdiff', 'diff.exe'),
		:sudo => find_executable('sudo'),
		:rcov => find_executable('rcov', 'rcov.bat'),
		:rdoc => find_executable('rdoc', 'rdoc.bat'),
		:gem  => find_executable('gem', 'gem.bat', 'gem1.8'),
		:git  => find_executable('git')
	)

	class <<BoneSplitter
		attr_accessor :libs, :bin
	end
	
	private
	def optional_task(name, depends_on_constant)
		# puts "#{name} requires #{depends_on_constant}: #{!!deep_const(depends_on_constant)}"
		if deep_const(depends_on_constant) then
			yield
		else
			task name do
				"You're missing a dependency to run this thread (#{depends_on_constant})"
			end
		end
	end
	
	def deep_const(name)
		name.split(/::/).inject(Object) { |nesting, name|
			return nil unless nesting.const_defined?(name)
			nesting.const_get(name)
		}
	end

	def version_proc(constant)
		proc {
			file    = constant.gsub(/::/, '/').downcase
			require(file)
			version = deep_const(constant)
			version && version.to_s
		}
	end
	
	def quietly
		verbose, $VERBOSE = $VERBOSE, nil
		yield
	ensure
		$VERBOSE = verbose
	end
	
	def silenced
		a,b     = $stderr, $stdout
		$stderr = StringIO.new
		$stdout = StringIO.new
		yield
	ensure
		$stderr, $stdout = a,b
	end
	
	# same as lib? but aborts if a dependency isn't met
	def dependency(names, warn_message=nil)
		abort unless lib?(names, warn_message)
	end
	alias dependencies dependency
	
	def lib?(names, warn_message=nil)
		Array(names).map { |name|
			next true if BoneSplitter.libs[name] # already been required earlier
			begin
				silenced do
					require name
				end
				BoneSplitter.libs[name] = true
				true
			rescue LoadError
				warn(warn_message % name) if warn_message
				false
			end
		}.all? # map first so we get all messages at once
	end
	
	# Add a lib as present. Use this to fake existence of a lib if you have
	# an in-place substitute for it, like e.g. RDiscount for Markdown.
	def has_lib!(*names)
		names.each { |name|
			BoneSplitter.libs[name] = true
		}
	end
	
	def manifest(mani=Project.meta.manifest)
		if File.exist?(mani) then
			File.read(mani).split(/\n/)
		else
			[]
		end
	end
	
	def bin
		BoneSplitter.bin
	end
	
	def manifest_candidates
		cands = Array(Project.manifest.include || '**/*').inject([]) { |a,e| a+Dir[e] }

		# remove all that are to exclude
		if Project.manifest.exclude then
			Project.manifest.exclude.map { |glob| cands -= Dir[glob] }
		end
		# remove all directories
		cands - Dir['**/*/'].map { |e| e.chop }
	end

	def has_version?(having_version, minimal_version, maximal_version=nil)
		a = having_version.split(/\./).map { |e| e.to_i }
		b = minimal_version.split(/\./).map { |e| e.to_i }
		c = maximal_version && maximal_version.split(/\./).map { |e| e.to_i }
		c ? a.between?(b,c) : a >= b
	end

	# requires that 'readme' is a file in markdown format and that Markdown exists
	def extract_summary(file=Project.meta.readme)
		return nil unless File.readable?(file)
		case File.extname(file)
			when '.rdoc'
				File.read('README.rdoc')[/^(\s*=+)\s+SUMMARY\b.*?\n(.*?)\n\1/m, 2]
			when '.markdown'
				return nil unless lib?(%w'hpricot markdown', "Requires %s to extract the summary")
				html = Markdown.new(File.read(file)).to_html
				(Hpricot(html)/"h2[text()=Summary]").first.next_sibling.inner_text.strip
		end
	rescue => e
		warn "Failed extracting the summary: #{e}"
		nil
	end
	
	# requires that 'readme' is a file in markdown format and that Markdown exists
	def extract_description(file=Project.meta.readme)
		return nil unless File.readable?(file)
		case File.extname(file)
			when '.rdoc'
				File.read('README.rdoc')[/^(\s*=+)\s+DESCRIPTION\b.*?\n(.*?)\n\1/m, 2]
			when '.markdown'
				return nil unless lib?('hpricot markdown', "Requires %s to extract the summary")
				html = Markdown.new(File.read(file)).to_html
				(Hpricot(html)/"h2[text()=Description]").first.next_sibling.inner_text.strip
		end
	rescue => e
		warn "Failed extracting the description: #{e}"
		nil
	end
	
	# Create a Gem::Specification from Project.gem data.
	def gem_spec(from)
		Gem::Specification.new do |s|
			s.name                  = from.name
			s.version               = from.version
			s.summary               = from.summary
			s.authors               = from.authors
			s.email                 = from.email
			s.homepage              = from.homepage
			s.rubyforge_project     = from.rubyforge_project
			s.description           = from.description
			s.required_ruby_version = from.required_ruby_version if from.required_ruby_version
	
			from.dependencies.each do |dep|
				s.add_dependency(*dep)
			end if from.dependencies
	
			s.files            = from.files
			s.executables      = from.executables.map {|fn| File.basename(fn)}
			s.extensions       = from.extensions
	
			s.bindir           = from.bin_dir
			s.require_paths    = from.require_paths if from.require_paths
	
			s.rdoc_options     = from.rdoc_options
			s.extra_rdoc_files = from.extra_rdoc_files
			s.has_rdoc         = from.has_rdoc
	
			if from.test_file then
				s.test_file  = from.test_file
			elsif from.test_files
				s.test_files = from.test_files
			end
			
			# Do any extra stuff the user wants
			from.extras.each do |msg, val|
				case val
					when Proc
						val.call(s.send(msg))
					else
						s.send "#{msg}=", val
				end
			end
		end # Gem::Specification.new
	end

	# Returns a good name for the gem-file using the spec and the package-name.	
	def gem_file(spec, package_name)
		if spec.platform == Gem::Platform::RUBY then
			"#{package_name}.gem"
		else
			"#{package_name}-#{spec.platform}.gem"
		end
	end
end # BoneSplitter
