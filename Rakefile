$VERBOSE = nil

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'pp'

include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'color', 'version')

RDOC_OPTS         = [
	'--quiet',
	'--title', 'The Color Reference',
	'--main',  'README',
	'--charset', 'utf-8',
	'--inline-source',
	'--tab-width', '2',
	'--line-numbers',
]
GEM_NAME          = 'color'
RUBYFORGE_PROJECT = 'color' # The unix name for your project
HOMEPATH          = "http://#{RUBYFORGE_PROJECT}.rubyforge.org/"
DOWNLOAD_PATH     = "http://rubyforge.org/projects/#{RUBYFORGE_PROJECT}"
NAME              = "color"
PATH              = (RUBYFORGE_PROJECT == GEM_NAME) ? RUBYFORGE_PROJECT : "#{RUBYFORGE_PROJECT}/#{GEM_NAME}"
ARCHLIB           = "lib/#{::Config::CONFIG['arch']}"
BIN               = "*.{bundle,jar,so,obj,pdb,lib,def,exp}"
REV               = nil 
VERS              = Color::VERSION::STRING + (REV ? ".#{REV}" : "")
CLEAN.include [
	'ext/**/#{BIN}',
	'**/.*.sw?', '**/*.o', '*.gem', '.config',
	'**/.DS_Store', '**/._*',
]
PKG_FILES         =
	%w[CHANGELOG COPYING README Rakefile] +
  Dir.glob("{test,lib}/**/*") + 
  Dir.glob("ext/**/*.{h,c,rb}")

GemSpec = Gem::Specification.new do |s|
	s.homepage          = HOMEPATH
	s.name              = GEM_NAME
	s.version           = VERS

	s.author            = "Stefan Rusterholz"
	s.email             = 'apeiros@gmx.net'

	s.platform          = Gem::Platform::RUBY
	s.has_rdoc          = true
	s.extra_rdoc_files  = %w[README CHANGELOG COPYING]
	s.summary           = "Color classes - classes to handle and manipulate colors."
	s.description       = s.summary
	s.files             = PKG_FILES
	s.require_paths     = ["lib/#{::Config::CONFIG['arch']}", "lib"]
	s.extensions       << "ext/ccolor/extconf.rb"
	s.rdoc_options     += RDOC_OPTS
end

Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir  = 'doc/rdoc'
    rdoc.options  += RDOC_OPTS
    rdoc.main      = "README"
    rdoc.rdoc_files.add [
    	'README',
    	'CHANGELOG',
    	'COPYING',
    	'lib/**/*.rb'
    ]
end

Rake::GemPackageTask.new(GemSpec) do |p|
    p.need_tar = true
    p.gem_spec = GemSpec
end

Rake::TestTask.new do |t|
	t.libs       << "test"
	t.test_files  = FileList['test/**/test_*.rb']
	t.verbose     = true
end

desc 'Install extension and library'
task :install => [:clean, :install_ext, :install_lib]

desc 'Install extension'
task :install_ext => :build do
end

#desc 'Build extension'
#taks :build => EXT_SO

#file EXT_SO => 'ext/ccolor/Makefile' do
#end

desc 'Release the website and new gem version'
task :deploy => [:check_version, :website, :release] do
  puts "Remember to create SVN tag:"
  puts "svn copy svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/trunk " +
    "svn+ssh://#{rubyforge_username}@rubyforge.org/var/svn/#{PATH}/tags/REL-#{VERS} "
  puts "Suggested comment:"
  puts "Tagging release #{CHANGES}"
end

desc 'Runs tasks website_generate and install_gem as a local deployment of the gem'
task :local_deploy => [:website_generate, :install_gem]

desc 'Install the package as a gem'
task :install_gem => [:clean, :package] do sh "sudo gem install pkg/*.gem" end

desc 'Generate website files'
task :website_generate do
  Dir['website/**/*.txt'].each do |txt|
    sh %{ ruby scripts/txt2html #{txt} > #{txt.gsub(/txt$/,'html')} }
  end
end

desc 'Upload website files to rubyforge'
task :website_upload do
  host       = "#{rubyforge_username}@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/#{PATH}/"
  local_dir  = 'website'
  sh %{rsync -aCv #{local_dir}/ #{host}:#{remote_dir}}
end

desc 'Generate and upload website files'
task :website => [:website_generate, :website_upload, :publish_docs]
