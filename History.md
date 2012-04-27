# 0.1.1 - 2012-04-27

Documentation and debugging enhancements.

Setup now properly uses --no-privileges

Restore now ensures it uses the correct schema and loops over the change rows.

# 0.1.0 - 2012-04-24

Ensure pgpass file is created if it does not exist.

Ensure connections get closed.

Account for setting schema when restoring.

Specify schema in --table specifier within pg\_dump command.

# 0.0.9 - 2012-04-23

Dump now uses --no-privileges, privileges should be handled separately.

# 0.0.8 - 2012-04-23

Corrected error message.

Added overview to README as well as some clarifying changes.

Added submit examples to README.

# 0.0.7 - 2012-04-20

--database CLI option for specifying a single database name.

--change CLI option for submitting either a sql change string or an sql change
file name.

Implemented 'submit' action.

# 0.0.6 - 2012-04-20

Merged {base.sql, cm.sql} into a single sql-path/{database}/{schema}.sql file.

Base is now the first change in the {schema}.sql CM file.

Made Configuration Managment table name configurable via cli using -c|--cm-table=

Made debug message output more structured and clear.

Created {drop,create,setup,dump,restore} rake tasks for qa-ing.

# 0.0.5 - 2012-04-18

Added git repository feature to sql-path for dump action, a commit per run of
the dump action occurs.

Bugfix: do not write pgpass line multiple times to the file.

# 0.0.4 - 2012-04-18

'restore' action functional.

# 0.0.3 - 2012-04-18

'setup' action functional.

# 0.0.2 - 2012-04-18

Initial 'dump' feature.

# 0.0.1 - 2012-04-17

Project setup, initial gem pushed to rubygems.org
