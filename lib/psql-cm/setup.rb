module PSQLCM
  class << self
    def setup!
      tree.each_pair do |database, schemas|
        ensure_database_exists(database)
        schemas(database).each do |schema|
          ensure_schema_exists(database,schema)
          ensure_cm_table_exists(database,schema)

          Tempfile.open('base.sql') do |temp_file|
            sh %W[ pg_dump #{db(database).psql_args}
            --schema-only --no-owner --no-privileges
            --schema=#{schema} --file=#{temp_file.path} #{database}
            ]

            content = %x{cat #{temp_file.path}}
            name = %x{git config user.name}.strip
            email = %x{git config user.email}.strip
            implementer = "#{name}"
            implementer << "<#{email}>" unless email.empty?

            db(database).exec(
              "INSERT INTO #{schema}.#{config.cm_table}
              (is_base, implementer, content)
              VALUES (true, $1, $2);",
              [implementer, content]
            )
          end
        end
      end

      dump!
    end
  end
end
