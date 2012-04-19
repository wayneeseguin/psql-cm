lib = File.expand_path('../lib/', __FILE__)

$:.unshift lib unless $:.include?(lib)

def psqlcm(params = {})
  command = ["psql-cm"]
  command << "--database #{params["database"] ? params["database"] : 'psqlcm_development'}"
  command << '-D' if ENV['debug']
  command << params[:actions].split

  $stdout.puts command.join(' ') if ENV['debug']
  exec command.join(' ')
end

desc "Build the psql-cm gem."
task :build do
  %x{gem build psql-cm.gemspec}
end

desc "Build then install the psql-cm gem."
task :install => :build do
  require 'psql-cm/version'
  %x{gem install psql-cm-#{::PSQLCM::Version}.gem}
end

task :default => :install

task :dev => :install do
  Rake::Task['install'].invoke
  ENV['debug'] = "true"
end

desc "Development console, builds installs then runs console"
task :console => :install do
  psqlcm :actions => 'console'
end

task :release do
  require 'psql-cm/version'

  %x{git tag -a #{::PSQLCM::Version}}
  %x{git push origin --tags}
  %x{gem build psql-cm.gemspec}
  %x{gem push psql-cm-#{::PSQLCM::Version}.gem}
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
