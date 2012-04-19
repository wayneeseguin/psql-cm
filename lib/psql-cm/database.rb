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
    def __setobj__(object) ;  end

    def db
      unless @config[:dbname] == 'postgres'
        ::PSQLCM.sh 'createdb', "createdb #{psql_args} #{@config[:dbname]}"
      end

      @db || connect!
    end

    def connect!
      @db = PG.connect(@config)
    end

    def reconnect!(name = @config[:dbname])
      close!
      connect!
    end

    def close!
      @db.close
    end

    def pgpass # Ensure a pgpass entry exists for this connection.
      pgpass_line = [ @config[:host], @config[:port], @config[:dbname],
                      @config[:user], @config[:password] ].join(':')

      content = File.open(File.join(ENV['HOME'], '.pgpass'), 'r') do |file|
        file.read
      end.split("\n")

      unless content.detect{ |line| line == pgpass_line }
        File.open(File.join(ENV['HOME'], '.pgpass'), 'w') do |file|
          content << pgpass_line
          file.write(content.join("\n") + "\n")
        end
        File.chmod(0600, File.join(ENV['HOME'], '.pgpass'))
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

    # "postgres://{user}:{password}@{host}:{port}/{database}"
    def configure!
      uri = URI.parse(::PSQLCM.config.uri)

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
