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

              file = File.open(psqlrc_file,'w')
              file.write "SET search_path TO #{schema}; "
              file.close

              begin
                tag = "restore:#{database}:#{schema}>"
                debug tag, cm_file
                sh "psql #{db(database).psql_args} #{database} < #{cm_file}"

                ensure_cm_table_exists(database,schema)

                sql = "SELECT content from #{schema}.#{config.cm_table}
                       WHERE is_base IS true ORDER BY created_at ASC;"
                debug tag, "base:sql> #{sql}"
                db(database).exec(sql).each do |base_row|
                  debug "BASE content:", base_row['content']
                  tempfile = Tempfile.open('base.sql')
                  tempfile.write(base_row['content'])
                  sh "psql #{db(database).psql_args} #{database} < #{tempfile.path}"
                  tempfile.close
                end

                sql = "SELECT content from #{schema}.#{config.cm_table}
                       WHERE is_base IS false
                       ORDER BY created_at ASC;"

                debug tag, "changes:sql> #{sql}"
                changes = db(database).exec(sql)
                debug tag, "change:count>#{changes.cmd_tuples}"
                changes.each do |row|
                  debug tag, "content>\n#{row['content']}"
                  tempfile = Tempfile.open('change.sql')
                  tempfile.write(row['content'])
                  sh "psql #{db(database).psql_args} #{database} < #{tempfile.path}"
                  tempfile.close
                end
              ensure
                file = File.open(psqlrc_file,'w')
                file.write psqlrc
                file.close
              end
            end
          end
        end
      end
    end # def restore!

  end # class << self
end # module PSQLCM
