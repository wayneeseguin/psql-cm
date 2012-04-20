module PSQLCM
  class << self
    def submit!
      puts "TODO: allow change string and/or file to be specified and add to the
      specified database scema control table"

      if config.content.to_s.empty?
        halt! "Content must be given! (--content=<file or \"sql string\">)"
      elsif File.exists?(config.content)
        content = File.open(config.content, 'r') { |file| file.read }
      else # SQL String
        content = %x{cat #{temp_file.path}}
      end

      debug "validate> #{database}.#{schema}.#{config.cm_table}: #{config.content}"

      # TODO:
      # - Ensure no 'INSERT' or 'COPY' if SQL string.
      # - Transactional Validation

      name = %x{git config user.name}.strip
      email = %x{git config user.email}.strip
      implementer = "#{name}"
      implementer << "<#{email}>" unless email.empty?

      debug "submit> #{database}.#{schema}.#{config.cm_table}: #{config.content}"
      db(database).exec(
        "INSERT INTO #{schema}.#{config.cm_table}
          (is_base,implementer,content)
          VALUES (false,$1,$2)",
            [implementer,content]
      )
    end # def submit!

    private

    def validate(change)

    end
  end
end
