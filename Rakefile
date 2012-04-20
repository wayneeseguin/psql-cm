lib = File.expand_path('../lib/', __FILE__)

$:.unshift lib unless $:.include?(lib)

def database
  @database ||= ENV["database"] || 'psqlcm_development'
end

def psqlcm(action, params = {})
  command = "psql-cm #{action}"
  params[:database] ||= database
  [:database,:schema,:change].each do |param|
    if params[param]
      command << " --#{param} '#{params[param]}'"
      params.delete(param)
    end
  end
  shell command, params
end

def shell(command, options = {})
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
  shell "gem build psql-cm.gemspec"
end

desc "Build then install the psql-cm gem."
task :install => :build do
  require 'psql-cm/version'
  shell "gem install psql-cm-#{::PSQLCM::Version}.gem"
end

desc "Development console, builds installs then runs console"
task :console => :install do
  psqlcm 'console', :exec => true
end

desc "Drop the development database #{database}"
task :drop do
  shell "dropdb #{database};"
end

desc "Create the development database #{database}, including two schemas."
task :create => [:debug, :install] do
  shell "
    createdb #{database} &&
    psql #{database} -c '
        CREATE SCHEMA schema_one;
        CREATE SCHEMA schema_two;
        CREATE TABLE public.a_bool(a BOOL);
        CREATE TABLE schema_one.an_integer(an INTEGER);
        CREATE TABLE schema_two.a_varchar(a VARCHAR);'
  "
end

desc "Run psql-cm restore action on #{database}."
task :setup do
  psqlcm "setup"
end

desc "Remove the sql/ directory in the current working directory."
task :clean do
  FileUtils.rm_rf("#{ENV['PWD']}/sql") if Dir.exists?("#{ENV['PWD']}/sql")
end

desc "Run psql-cm restore action on #{database}."
task :dump => [:clean] do
  psqlcm "dump"
end

desc "Run psql-cm restore action on #{database}."
task :restore do
  psqlcm "restore"
end

namespace :submit do
  task :string => [:install] do
    sql = "ALTER TABLE a_varchar ADD COLUMN a_timestamp timestamptz;"
    psqlcm "submit", :schema => "schema_two", :change => sql
  end

  task :file => [:install] do
    sql = "CREATE TABLE a_timestamp (a_timestamp timestamptz);"
    require 'tempfile'
    Tempfile.open('change.sql') do |change_file|
      change_file.write sql
      psqlcm "submit", :schema => "schema_two", :change => change_file.path
    end
  end
end

task :release do
  require 'psql-cm/version'
  shell "
  git tag #{::PSQLCM::Version};
  git push origin --tags;
  gem build psql-cm.gemspec;
  gem push psql-cm-#{::PSQLCM::Version}.gem;
  "
end
