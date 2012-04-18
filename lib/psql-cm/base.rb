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
      @config ||= OpenStruct.new
    end

    def databases
      @databases = db.
        exec("SELECT datname as name FROM pg_database WHERE datname !~ 'template*|postgres';").
        map {|row| row["name"]}

      unless config.databases.to_a.empty? # filter out databases not specified.
        @databases.select!{ |name| config.databases.include?(name) }
      end

      debug "databases> #{@databases}"
      @databases
    end

    def schemas(name = 'postgres')
      @schemas = db(name).
        exec("SELECT nspname as name FROM pg_namespace WHERE nspname !~ '^pg_.*|information_schema';").
        map{|row| row["name"]}
      debug "schemas> #{@schemas}"
      @schemas
    end

    def tree
      return @tree if @tree
      @tree = {}
      databases.each do |dbname|
        @tree[dbname] = {}
        schemas(dbname).each do |schema|
          @tree[dbname][schema] = ['base.sql', 'cm.sql']
        end
      end
      debug "tree> tree: #{@tree}"
      @tree
    end

    def dump!
      unless config.sql_path
        $stdout.puts "Warning: --sql-path was not set, defaulting to $PWD/sql."
        config.sql_path = "#{ENV["PWD"]}/sql"
      end

      debug "dump> sql_path: #{config.sql_path}"
      FileUtils.mkdir(config.sql_path) unless File.directory?(config.sql_path)
      Dir.chdir(config.sql_path) do
        tree.each_pair do |database, schema_hash|
          debug "dump> database: #{database}"

          File.directory?(File.join(config.sql_path,database)) or
            FileUtils.mkdir(File.join(config.sql_path,database))

          schema_hash.each_pair do |schema, files|
          debug "dump> schema: #{schema}"
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
            debug "dump> #{command}"

            %x[#{command}]
          end
        end
      end
    end # def dump!

    def setup!
      # Create psql_cm tables for each schema on the target db.
    end

    def load!
      # TODO: Load psql-cm filesystem path files {base,cm}.sql into database
      # structure.
    end

    def run!(action = config.action, parent_id = config.parent_id)
      case action
      when "console"
        ::PSQLCM.debug "Starting Console"
        require 'psql-cm/cli'
        ::PSQLCM::Console.run!
      when "dump"
        dump!
      when "restore"
        restore!
      when "setup"
        setup!
      else
        halt! "Action '#{action}' is not handled."
      end
    end

  end # class << self
end

::PSQLCM.config.debug = !!ENV['DEBUG']

