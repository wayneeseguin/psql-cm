require 'uri'

module PSQLCM
  # "postgres://{user}:{password}@{host}:{port}/{database}"
  class << self
    def db
      return @db if @db
      connect!
    end

    def connect!
      @config.connection ||= {"dbname" => "postgres"}
      @db = PG.connect(@config.connection)
    end

    def reconnect!
      @db.close
      connect!
    end

    def configure!(uri)
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

