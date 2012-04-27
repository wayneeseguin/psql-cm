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

              psqlrc_file = File.join(ENV['HOME'],'.psqlrc')
              FileUtils.touch(psqlrc_file) unless File.exists?(psqlrc_file)
              psqlrc = File.read(psqlrc_file)
              File.open(psqlrc_file,'w') do |file|
                file.rewind
                file.write "SET search_path TO #{schema}; "
              end

              begin
                tag = "restore:#{database}:#{schema}>"
                debug tag, cm_file
                sh "psql #{db(database).psql_args} #{database} < #{cm_file}"

                ensure_cm_table_exists(database,schema)

                sql = "SELECT content from #{schema}.#{config.cm_table}
                       WHERE is_base = $1 ORDER BY created_at ASC;"

                Tempfile.open('base.sql') do |temp_file|
                  debug tag, "base:sql> #{sql.sub('$1','true')}"
                  row = db(database).exec(sql, ['true'])
                  temp_file.write(row)
                  sh "psql #{db(database).psql_args} #{database} < #{temp_file.path}"
                end

                debug tag, "changes:sql> #{sql.sub('$1','false')}"
                changes = db(database).exec(sql,['false'])
                debug tag, "change:count>#{changes.cmd_tuples}"
                changes.each do |row|
                  debug tag, "content>\n#{row['content']}"
                  Tempfile.open('change.sql') do |temp_file|
                    temp_file.write(row['content'])
                    temp_file.close
                    sh "psql #{db(database).psql_args} #{database} < #{temp_file.path}"
                  end
                end
              ensure
                File.open(psqlrc_file,'w') do |file|
                  file.rewind
                  file.write psqlrc
                end
              end
            end
          end
        end
      end
    end # def restore!

  end # class << self
end # module PSQLCM
