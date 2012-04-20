# PostgreSQL Change Management Tool

## What psql-cm is

This project is a tool to assist with an ITIL like change management process
for *database schemas* within a PostgreSQL database cluster.

Specifically psql-cm is a tool which encodes *one* change management process
for a complex multi database, multi schema PostgreSQL system.

This means that psql-cm may be much more than you need for a simple
single database system.  Please take the time to understand the process and
what problems it solves. In order for psql-cm to be effective it must be
combined with complimentary process and adherence.

## What psql-cm is not

psql-cm is not intended on being a solution for data backup.
For backup of data instead use the
[pg\_dump](http://www.postgresql.org/docs/current/static/app-pgdump.html)
command line utility for backing up data in addition to a
[repliaction](http://www.postgresql.org/docs/current/static/different-replication-solutions.html)
technique tailored to your needs.

## The process

# Using psql-cm

## Prerequisites

- [Ruby >= 1.9.3](http://www.ruby-lang.org/en/)
- [Postgresql >= 9.1+](http://www.postgresql.org/)
- [Git SCM](http://git-scm.com/)

## Installation

Once the prerequisites have been satisfied on your system, using the
'gem' command from Ruby 1.9.3 do:

    $ gem install psql-scm

## Setup

Setup the psql\_cm control tables on the target databases, use a comma (',')
to separate multiple database names.

    $ psql-cm setup --database psqlcm_test

## Dump

Dump the current database schema to the specified --sql-path directory, if none
specified it dumps to $PWD/sql

    $ psql-cm dump --database psqlcm_test

## Restore

Restore a previously psql-cm dumped database schema into a brand new postgresql
database cluster.

    $ psql-cm restore --database psqlcm_test

## Submit

There are two ways to submit schema changes. The first is by passing the schema
change on the command line as a string and the second is by specifying the path
to a sql file. An example of each follows.

### SQL String

    $ psql-cm submit --database psqlcm_test --change "ALTER TABLE schema_two.a_varchar ADD COLUMN a_timestamp timestamptz;"

### SQL File

    $ echo "ALTER TABLE schema_two.a_varchar ADD COLUMN a_timestamp timestamptz;" > add_a_timestamp.sql
    $ psql-cm submit --database psqlcm_test --change add_a_timestamp.sql

## Command line parameters

--database argument specifies a single database name and can be used multiple
times if required, although using the --databases argument (below) is more
succient and preferred.

    $ psql-cm --database adatabase

--database argument may take multiple database targets, to do this pass them
in ',' separated format, no spaces. Specifically the format is,

    $ psql-cm --databases adatabase,anotherdatabase,... ...

--uri can be given to change from the default of "postgres://127.0.0.1:5432" and
has the format,

    $ psql-cm --uri "postgres://{user}:{password}@{host}:{port}/{database}?{sslmode}={mode}"

Host and database are the only required entries in a uri string. Eg.  user,
password, port, the ? and everything after it (the query) are all optional.

sslmode mode may be one of {disable, allow, prefer, require} if it is used.

# Walkthrough

First let's create a PostgreSQL database for us to work with,

    $ createdb psqlcm_test

Next let's create two schemas in addition to the public schema (which is added
by default when the database is created) and a table for each schema for our
database.

    $ psql psqlcm_test -c '
        CREATE SCHEMA schema_one;
        CREATE SCHEMA schema_two;
        CREATE TABLE public.a_bool(a BOOL);
        CREATE TABLE schema_one.an_integer(an INTEGER);
        CREATE TABLE schema_two.a_varchar(a VARCHAR);'


Now that we have a base set of database(s) and schemas that we wish to apply
change management process to we can setup the psql-cm control tables.

The setup action adds one table called 'pg\_psql\_cm' to each of the target
database schemas.

    $ psql-cm --database psqlcm_test setup

Use a PostgreSQL client tool (psql/pgAdmin/Navicat/...) and examine the schemas
for the psqlcm\_test database for which there should be three:

    public
    schema_one
    schema_two

each with two tables, the pg\_psql\_cm control table and one other table.

Next we'll dump the schema to sql/ within our working directory

    $ psql-cm --database psqlcm_test dump

At this point we have the base schema for the psqlcm\_test database recorded to
the filesystem. You can see the filesystem structure and contents with
a find command on \*nix:

    $ find sql/psqlcm_test/
    sql/psqlcm_test
    sql/psqlcm_test/public.sql
    sql/psqlcm_test/schema_one.sql
    sql/psqlcm_test/schema_two.sql

We can now do a restore restore by droping the database and then running the
psql-cm restore action.

    $ dropdb psqlcm_test
    $ psql-cm --database psqlcm_test restore

Once again useing a client tool and verify that the schema is inded what it was
after setup was run.

NOTE: one caveat is that psql-cm does not handle ROLEs and USERs so these will
have to be accounted for after doing a restore.

## Debugging

Debugging output can be enabled by exporting DEBUG=true in the environment
before calling the psql-cm command:

    $ export debug=true

## Development

To play around inside of a running psql-cm Ruby environment use the console:

    rake console    # Development console, builds installs then runs console

The 'Walkthrough' from above is encoded as rake tasks, each step can be
seen including all debugging output by running:

    rake clean      # Remove the sql/ directory in the current working directory.
    rake create     # Create the development database psqlcm_development, including two schemas.
    rake debug      # Enable debugging using environment variable DEBUG
    rake drop       # Drop the development database psqlcm_development
    rake dump       # Remove sql/ from CWD and then run the psql-cm dump action on psqlcm_development
    rake build      # Build the psql-cm gem.
    rake install    # Build then install the psql-cm gem.
    rake restore    # Create psqlcm_development, run psql-cm actions {setup, dump, restore} in order.
    rake setup      # Create psqlcm_development and run psql-cm setup on it

