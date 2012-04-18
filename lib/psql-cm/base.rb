module PSQLCM
  class << self
    def verbose(message)
      $stdout.puts message if (config.verbose || config.debug)
    end

    def debug(message)
      $stdout.puts message if config.debug
    end

    def halt!(message)
      $stderr.puts message
      exit 1
    end

    def config
      require 'ostruct'
      @config ||= OpenStruct.new
    end # def self.config

    def databases
      @databases = db.
        exec("SELECT datname as name FROM pg_database WHERE datname !~ 'template*|postgres';").
        map {|row| row["name"]}

      unless config.databases.empty?
        @databases.select!{ |name| config.databases.include?(name) }
      end
    end

    def schemas
      @schemas = db.
        exec("SELECT nspname as name FROM pg_namespace WHERE nspname !~ '^pg_.*|information_schema';").
        map{|row| row["name"]}
    end

    def tree
      return @tree if @tree
      @tree = {}
      databases.each do |name|
        debug "tree> database: #{name}"
        @config.connection["dbname"] = name and reconnect!
        @tree[name] = {}
        schemas.each do |schema|
          debug "tree>   schema: #{schema}"
          @tree[name][schema] = ['base.sql', 'cm.sql']
        end
      end
      @tree
    end

    def generate!
      unless config.sql_path
        $stdout.puts "Warning: --sql-path was not set, defaulting to $PWD/sql."
        config.sql_path = "#{ENV["PWD"]}/sql"
      end

      FileUtils.mkdir(config.sql_path) unless File.directory?(config.sql_path)

      debug "generate> sql_path: #{config.sql_path}"
      Dir.chdir(config.sql_path) do
        tree.each_pair do |database, hash|
          debug "generate> database: #{database}"

          File.directory?(File.join(config.sql_path,database)) or
            FileUtils.mkdir(File.join(config.sql_path,database))

          hash.each_pair do |schema, files|
          debug "generate> schema: #{schema}"
            File.directory?(File.join(config.sql_path,database,schema)) or
              FileUtils.mkdir(File.join(config.sql_path,database,schema))

            base_file = File.join(config.sql_path,database,schema,'base.sql')
            cm_file = File.join(config.sql_path,database,schema,'cm.sql')

            FileUtils.touch(base_file)
            FileUtils.touch(cm_file)

            command = "pg_dump --schema-only --no-owner --schema=#{schema} "
            if File.size(base_file) > 0
              command += "--file=#{cm_file}  --table=psql_cm "
            else
              command += "--file=#{base_file} --exclude-table=psql_cm "
            end
            command += "#{database}"
            debug "generate> #{command}"

            %x[#{command}]
          end
        end
      end
    end

    def run!(action = config.action, parent_id = config.parent_id)
      case action
      when "console"
        ::PSQLCM.debug "Starting Console"
        require 'psql-cm/cli'
        ::PSQLCM::Console.run!
      when "generate"
        generate!
      else
        halt! "Action '#{action}' is not handled."
      end
    end

  end # class << self
end

::PSQLCM.config.debug = !!ENV['DEBUG']

