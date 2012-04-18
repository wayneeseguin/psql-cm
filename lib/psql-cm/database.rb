module PSQLCM
  class Connection < Delegator
    def initialize(options = {})
      @name = options[:dbname] || 'postgres'
      @config = ::PSQLCM.config.connection.merge(options)

      super # For delegator pattern:
      @delegated_object = db
    end

    # Delegator to PG::Connection
    def __getobj__ ; @db end
    def __setobj__(object) ;  end

    def db
      @db || connect!
    end

    def connect!
      @db = PG.connect(@config)
    end

    def reconnect!(name = @name)
      close!
      connect!
    end

    def close!
      @db.close
    end
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
        :user => uri.user,
        :password => uri.password,
        :connect_timeout => timeout.empty? ? 20 : timeout.to_i,
        :sslmode => sslmode.empty? ? "disable" : sslmode # (disable|allow|prefer|require)
      }.delete_if { |key, value| value.nil? }
    end
  end # class << self

end # module PSQLCM
