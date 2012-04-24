module PSQLCM

  class Connection < Delegator

    def initialize(options = {})
      @config = ::PSQLCM.config.connection.merge(options)
      @config[:dbname] = options[:dbname] || 'postgres'

      super # For delegator pattern:
      @delegated_object = db
    end

    # Delegator to PG::Connection
    def __getobj__ ; @db end
    def __setobj__(object) end

    def db
      unless @config[:dbname] == 'postgres'
        ::PSQLCM.sh "createdb #{psql_args} #{@config[:dbname]}"
      end

      @db || connect!
    end

    def connect!
      @db = PG.connect(@config)
      ObjectSpace.define_finalizer(self, proc { @db.close })
      @db
    end

    def reconnect!(name = @config[:dbname])
      close!
      connect!
    end

    def close!
      @db.close
    end

    def pgpass # Ensure a pgpass entry exists for this connection.
      pgpass_file = File.join(ENV['HOME'], '.pgpass')
      FileUtils.touch(pgpass_file) unless File.exists?(pgpass_file)

      pgpass_line = [ @config[:host], @config[:port], @config[:dbname],
                      @config[:user], @config[:password] ].join(':')

      content = File.read(pgpass_file).split("\n")

      unless content.detect{ |line| line == pgpass_line }
        File.open(pgpass_file, 'w') do |file|
          content << pgpass_line
          file.write(content.join("\n") + "\n")
        end
        File.chmod(0600, pgpass_file)
      end
      pgpass_line
    end # def pgpass

    def psql_args
      pgpass
      "-h #{@config[:host]} -p #{@config[:port]} -U #{@config[:user]}"
    end # def psql_args

  end # class Connection

  class << self
    def db(name = 'postgres')
      @db ||= {}
      return @db[name] if @db[name]
      @config.connection || configure!

      @db[name] = Connection.new(:dbname => name)
    end

    def configure!
      begin
        uri = URI.parse(::PSQLCM.uri)
      rescue => error
        halt! "PostgreSQL URI was incorrectly specified, format is:\n  --uri=postgres://{user}:{password}@{host}:{port}/{database}\nwhere user, password, port and database are optional."
      end

      query = uri.query.to_s.split('&')

      timeout = query.detect { |k| k.match /connect_timeout=/ }.to_s.sub(/.*=/,'')
      sslmode = query.detect { |k| k.match /sslmode=/ }.to_s.sub(/.*=/,'')

      @config.connection = {
        :host => uri.host,
        :port => uri.port || 5432,
        :dbname => "postgres", # uri.path.sub('/',''),
        :user => uri.user || ENV['USER'],
        :password => uri.password,
        :connect_timeout => timeout.empty? ? 20 : timeout.to_i,
        :sslmode => sslmode.empty? ? "disable" : sslmode # (disable|allow|prefer|require)
      }.delete_if { |key, value| value.nil? }
    end
  end # class << self

end # module PSQLCM
