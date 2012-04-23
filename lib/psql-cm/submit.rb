module PSQLCM
  class << self
    def submit!
      databases.each do |database|
        schemas(database).each do |schema|
          if config.change.to_s.empty?
            halt! "Content must be given! (--change=<file or \"sql string\">)"
          elsif File.exists?(config.change)
            content = File.open(config.change, 'r') { |file| file.read }
          else # SQL String
            content = config.change
          end

          name = %x{git config user.name}.strip
          email = %x{git config user.email}.strip
          implementer = "#{name}"
          implementer << "<#{email}>" unless email.empty?

          debug "validate> #{database}.#{schema}.#{config.cm_table}: #{config.change}"

          # Transactional Validation -- Submit if successful, blow up otherwise.
          transaction = "BEGIN;SET search_path TO #{schema},public; #{content}; COMMIT;"
          result = db(database).exec(transaction)

          debug "submit> #{database}.#{schema}.#{config.cm_table}: #{config.change}"
          db(database).exec(
            "INSERT INTO #{schema}.#{config.cm_table}
          (is_base,implementer,content)
          VALUES (false,$1,$2)",
            [implementer,content]
          )
        end # schemas
      end # databases
    end # def submit!

    private

    def validate(change)

    end
  end
end
