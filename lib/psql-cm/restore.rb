module PSQLCM
  class << self
    def restore!
      File.directory?(sql_path) or
        halt! "Cannot restore from sql-path (#{sql_path}), it does not exist!"

      Dir.chdir(sql_path) do

        Dir['*'].each do |database|
          next unless File.directory? database

          Dir.chdir(database) do
            ensure_database_exists(database)

            debug "restore> #{database}"
            Dir['*.sql'].each do |cm_file|
              next if File.size(cm_file) == 0

              schema = cm_file.sub(".sql",'')
              ensure_schema_exists(database,schema)

              debug "restore> #{database}:#{schema} < #{cm_file}"
              sh "psql #{db(database).psql_args} #{database} < #{cm_file}"

              ensure_cm_table_exists(database,schema)
              row = db(database).exec("SELECT content from #{schema}.#{config.cm_table}
                                      WHERE is_base IS true ORDER BY created_at
                                      DESC LIMIT 1;")
              Tempfile.open('base.sql') do |temp_file|
                temp_file.write(row)
                sh "psql #{db(database).psql_args} #{database} < #{temp_file.path}"
              end

              sql = "SELECT content from #{schema}.#{config.cm_table} where is_base IS false ORDER BY created_at ASC;"
              db(database).exec(sql).each do |row|
                debug "restoring cm row: #{row}"
                Tempfile.open('base.sql') do |temp_file|
                  temp_file.write(row)
                  sh "psql #{db(database).psql_args} #{database} < #{temp_file.path}"
                end
              end
            end
          end
        end
      end
    end # def restore!

  end
end
