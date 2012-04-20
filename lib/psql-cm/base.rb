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
        map {|row| row['name']}

      if config.databases.empty?
        halt! 'A list of databases must be given:\n  --databases={database_one}[,{database_two}[,...]]'
      else # filter out databases not specified.
        @databases.select!{ |name| config.databases.include?(name) }
      end
      debug "databases> #{@databases}"
      @databases
    end

    def schemas(name = 'postgres')
      @schemas = db(name).
        exec("SELECT nspname AS name FROM pg_namespace WHERE nspname !~ '^pg_.*|information_schema';").
        map{|row| row['name']}

      # Filter out schemas not specified, if specified.
      @schemas.select!{ |name| config.schemas.include?(name) } if config.schemas
      debug "schemas> #{@schemas}"
      @schemas
    end

    def tree
      return @tree if @tree
      @tree = {}
      databases.each do |dbname|
        @tree[dbname] = schemas(dbname)
      end
      debug "tree> #{@tree}"
      @tree
    end

    def run!(action = config.action)
      case action
      when 'console'
        require 'psql-cm/cli'
        ::PSQLCM::Console.run!
      when 'dump'
        dump!
      when 'restore'
        restore!
      when 'setup'
        setup!
      when 'submit'
        submit!
      else
        halt! "An action must be given! {setup, dump, restore}" if action.nil?
        halt! "Action '#{action}' is not handled."
      end
    end

    def sh(command)
      debug "$ #{command}"
      %x[#{command} 2>&1 | awk '! /NOTICE/']
    end

    def uri
      return config.uri unless config.uri.to_s.empty?
      $stdout.puts "NOTICE: uri is not set, defaulting to postgres://127.0.0.1:5432 (format: postgres://{user}:{password}@{host}:{port}/{database} (where user, password, port and database are optional)"
      config.uri = "postgres://127.0.0.1:5432"
    end

    private

    def ensure_database_exists(database)
      begin
        db('postgres').exec("CREATE DATABASE #{database};")
        debug "create> #{database}"
      rescue => error
        raise error unless error.message =~ /already exists/
      end
    end

    def ensure_schema_exists(database,schema)
      begin
        db(database).exec("CREATE SCHEMA #{schema};")
        debug "create> #{database}.#{schema}"
      rescue => error
        raise error unless error.message =~ /already exists/
      end
    end

    def ensure_cm_table_exists(database,schema)
      sql = <<-SQL
        SET search_path = #{schema};
        SET client_min_messages = warning;
        CREATE TABLE IF NOT EXISTS #{schema}.#{config.cm_table}
        (
          id bigserial NOT NULL PRIMARY KEY ,
          is_base boolean NOT NULL,
          created_at timestamp with time zone DEFAULT now(),
          implementer text NOT NULL,
          content text NOT NULL
        );
      SQL
      debug "create> #{database}.#{schema}.#{config.cm_table}"
      db(database).exec(sql)
    end

    def sql_path
      return config.sql_path unless config.sql_path.to_s.empty?
      $stdout.puts "NOTICE: sql_path is not set, defaulting to #{ENV["PWD"]}/sql"
      config.sql_path = "#{ENV["PWD"]}/sql"
    end

  end # class << self
end

# Module configuration, initial values
::PSQLCM.config.debug = !!ENV['DEBUG']
::PSQLCM.config.cm_table = 'pg_psql_cm' # Default --cm-table name.
::PSQLCM.config.databases = []

