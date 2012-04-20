module PSQLCM
  class << self
    def submit!
      puts "TODO: allow change string and/or file to be specified and add to the
      specified database scema control table"

      # TOOD: get values x,y,z
      sql = "INSERT INTO #{schema}.#{config.cm_table} (is_base,implementer,content) VALUES (x,y,z)"
      debug "submit:#{database}:#{schema}> sql\n#{sql}"
      db(database).exec sql
    end # def submit!
  end
end

