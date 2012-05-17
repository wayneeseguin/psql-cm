module PSQLCM
  class << self
    def dump!
      debug "dump> sql_path: #{sql_path}"
      FileUtils.mkdir(sql_path) unless File.directory?(sql_path)
      Dir.chdir(sql_path) do
        debug "tree> #{tree}"
        tree.each_pair do |database, database_schemas|
          debug "dump> database: #{database}"
          FileUtils.mkdir_p(File.join(sql_path,database))
          database_schemas.each do |schema|
            debug "dump> schema: #{schema}"
            FileUtils.mkdir_p(File.join(sql_path,database))

            cm_file = File.join(sql_path,database,"#{schema}.sql")

            sh %W[ pg_dump #{db(database).psql_args}
                 --schema=#{schema} --file=#{cm_file}
                 --table=#{schema}.#{config.cm_table} #{database}
            ].join(' ')
          end
        end

        sh "git init; git add ." unless File.exists?('.git') && File.directory?('.git')

        sh "git commit -a -m 'PostgreSQL Change Management (psql-cm).\nDatabases: #{databases.join(', ')}\nTree: #{tree}'"
      end
    end # def dump!

  end
end
