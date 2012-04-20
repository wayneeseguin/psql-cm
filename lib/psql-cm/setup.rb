module PSQLCM
  class << self
    def setup!
      tree.each_pair do |database, schemas|
        ensure_database_exists(database)
        schemas(database).each do |schema|
          ensure_schema_exists(database,schema)
          ensure_cm_table_exists(database,schema)

          Tempfile.open('base.sql') do |temp_file|
            sh " pg_dump #{db(database).psql_args} --schema-only --no-owner --schema=#{schema} --file=#{temp_file.path} #{database}"

            contents = %x{cat #{temp_file.path}}
            implementer = %Q|#{%x[git config user.name].strip} <#{%x[git config user.email].strip}>|
            db(database).exec(
              "INSERT INTO #{schema}.#{config.cm_table} (is_base, implementer, content) VALUES (true, $1, $2);",
              [implementer, contents]
            )
          end

        end
      end

      dump!
    end
  end
end
