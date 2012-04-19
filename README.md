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

psql-cm is not intended on being a solution whatsoever for data backup.

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

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup

## Dump

Dump the current database schema to the specified --sql-path directory, if none
specified it dumps to $PWD/sql

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

## Restore

Restore a previously psql-cm dumped database schema into a brand new postgresql
database cluster.

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" restore

## Command line parameters

--databases argument may take multiple database targets, to do this pass them
in ',' separated format, no spaces. Specifically the format is,

    $ psql-cm --databases psqlcm_test,psqlcm_test2,... ...

--uri has the format,

    $ psql-cm --uri "postgres://{user}:{password}@{host}:{port}/{database}?{sslmode}={mode}

Where user, password, port, and sslmode are optional.

sslmode mode may be one of disable, allow, prefer, require

# Walkthrough

First let's create a PostgreSQL database for us to work with,
    $ createdb psqlcm_test

Next let's create two schemas in addition to the public schema (which is added
by default when the database is created) and a table for each schema for our
database.

    $ psql psqlcm_test -c '
        SET search_path = public;
        CREATE SCHEMA schema_one;
        CREATE TABLE a_bool(a BOOL);

        SET search_path = schema_one;
        CREATE TABLE an_integer(an INTEGER);

        CREATE SCHEMA schema_two;
        SET search_path = schema_two;
        CREATE TABLE a_varchar(a VARCHAR);'

Now that we have a base set of database(s) and schemas that we wish to apply
change management process to we can setup the psql-cm control tables.

The setup action adds one table called 'pg\_psql\_cm' to each of the target
database schemas.

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup

Use your favorite PostgreSQL client tool (psql/pgAdmin/Navicat/...) and examine
the schemas for the psqlcm\_test database for which there should be three,
public, schema\_one, schema\_two. each with two tables, the pg\_psql\_cm
control table and one other table.

Next we'll dump the schema to sql/ within our working directory

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

At this point we have the base schema for the psqlcm\_test database recorded and
we can test to see that this is true by droping the database and then running
the psql-cm restore action.

    $ dropdb psqlcm_test
    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" restore

Once again use yoru favorite client tool and verify that the schema is inded
what it was after setup was run.

Note that one caveat is that psql-cm does not handle ROLEs and USERs so these
will have to be accounted for after doing a restore.

