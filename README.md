# PostgreSQL Change Management Tool

This project is a tool for schema change management within a PostgreSQL database
cluster.

# Prerequisites

- [Ruby >= 1.9.3](http://www.ruby-lang.org/en/)
- [Postgresql >= 9.1+](http://www.postgresql.org/)
- [Git SCM](http://git-scm.com/)

# Installation of psql-cm

Once the prerequisites have been satisfied on your system, using the
'gem' command from Ruby 1.9.3 do:

    user$ gem install psql-scm

# Setup

Setup the psql\_cm control tables on the target databases, use a comma (',')
to separate multiple database names.

    user$ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup

# Dump

Dump the current database schema to the specified --sql-path directory, if none
specified it dumps to $PWD/sql

    user$ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

# Restore (Currently being implemented)

Restore a previously psql-cm dumped database schema into a brand new postgresql
database cluster.

    user$ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" restore

# Example

    user$ createdb psqlcm_test
    user$ psql psqlcm_test -c 'CREATE SCHEMA schema_one; CREATE SCHEMA schema_two'
    user$ echo psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup
    user$ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

