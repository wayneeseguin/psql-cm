require 'optparse'

module PSQLCM
  class CLI

    class << self
      def parse!(arguments)
        ::OptionParser.new do |options|
          options.banner = 'Usage: psql-cm [options]'
          options.separator ''
          options.separator 'Specific options:'

          options.on('-p', '--sql-path PATH', 'Path to dump SQL cm files into.') do |path|
            ::PSQLCM.config.sql_path = path
          end

          options.on('-d', '--database NAME', 'A single databases name.') do |name|
            ::PSQLCM.config.databases << name
          end

          options.on('-a', '--databases NAMES', 'A comma separated list of databases to cm.') do |names|
            ::PSQLCM.config.databases += names.split(',')
          end

          options.on('-s', '--schema NAME', 'A single schemas name.') do |name|
            ::PSQLCM.config.schemas << name
          end

          options.on('-m', '--schemas NAMES', 'A comma separated list of schemas to cm.') do |names|
            ::PSQLCM.config.schemas += names.split(',')
          end

          options.on('-u', '--uri URI', 'Path to the sink database connection file.') do |uri|
            ::PSQLCM.config.uri = uri
          end

          options.on('-c', '--change SQL|FILE') do |change|
            ::PSQLCM.config.change = change
          end

          options.on('-t', '--cm-table TABLE') do |cm_table|
            ::PSQLCM.config.cm_table = cm_table
          end

          options.on('-D', '--[no-]debug', 'Output debugging information.') do |debug|
            ::PSQLCM.config.debug = debug.nil? ? false : true
          end

          options.on('-v', '--[no-]verbose', 'Output verbosley.') do |verbose|
            ::PSQLCM.config.verbose = verbose
          end

          options.on_tail('-h', '--help', 'Print help and exit.') do
            puts options
            exit 0
          end

          options.on_tail('--version', 'Print version and exit.') do
            require 'psql-cm/version'
            puts ::PSQLCM::Version
            exit 0
          end

          options.parse!(arguments)

          options
        end # OptionParser.new
      end # def self.parse

    end # class << self
  end # class CLI

  class Console
    class << self

      def run!
        require 'irb'
        IRB.start
      end

    end # class << self
  end # class Console
end # module PSQLCM

