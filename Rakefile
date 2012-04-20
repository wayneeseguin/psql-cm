lib = File.expand_path('../lib/', __FILE__)

$:.unshift lib unless $:.include?(lib)

def database
  @database ||= ENV["database"] || 'psqlcm_development'
end

def psqlcm(action, params = {})
  command = %Q|psql-cm --databases #{database} #{action}|
  sh command, params
end

def sh(command, options = {})
  $stdout.puts command if ENV['debug'] || ENV['DEBUG']
  exec command if options[:exec]
  if ENV['verbose'] || ENV["VERBOSE"]
    puts %x{#{command}}
  else
    %x{#{command}}
  end
end

desc "Enable debugging using environment variable DEBUG"
task :debug do
  ENV['DEBUG'] = "true"
end

desc "Build the psql-cm gem."
task :build do
  sh "gem build psql-cm.gemspec"
end

desc "Build then install the psql-cm gem."
task :install => :build do
  require 'psql-cm/version'
  sh "gem install psql-cm-#{::PSQLCM::Version}.gem"
end

desc "Development console, builds installs then runs console"
task :console => :install do
  psqlcm 'console', :exec => true
end

desc "Drop the development database #{database}"
task :drop do
  sh "dropdb #{database};"
end

desc "Create the development database #{database}, including two schemas."
task :create => [:debug, :install] do
  sh "
    createdb #{database} &&
    psql #{database} -c '
        CREATE SCHEMA schema_one;
        CREATE SCHEMA schema_two;
        CREATE TABLE public.a_bool(a BOOL);
        CREATE TABLE schema_one.an_integer(an INTEGER);
        CREATE TABLE schema_two.a_varchar(a VARCHAR);'
  "
end

desc "Create #{database} and run psql-cm setup on it"
task :setup => [:create] do
  psqlcm "setup"
end

desc "Remove the sql/ directory in the current working directory."
task :clean do
  FileUtils.rm_rf("#{ENV['PWD']}/sql") if Dir.exists?("#{ENV['PWD']}/sql")
end

desc "Remove sql/ from CWD and then run the psql-cm dump action on #{database}"
task :dump => [:clean] do
  psqlcm "dump"
end

desc "Create #{database}, run psql-cm actions {setup, dump, restore} in order."
task :restore  => [:setup, :dump] do
  psqlcm "setup"
end

task :submit  => [:setup] do
  # TODO: Add some change submissions here
  psqlcm "submit"
end

task :release do
  require 'psql-cm/version'
  sh "
  git tag #{::PSQLCM::Version};
  git push origin --tags;
  gem build psql-cm.gemspec;
  gem push psql-cm-#{::PSQLCM::Version}.gem
  "
end

require 'rake/testtask'

task :spec => "spec:test"

namespace :spec do
  Rake::TestTask.new do |task|
    task.libs.push "lib"
    task.test_files = FileList['spec/*_spec.rb']
    task.verbose = true
  end
end
