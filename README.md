# PostgreSQL Change Management Tool

This project is a tool for schema change management within a PostgreSQL database
cluster.

# Setup (Currently being implemented)

Setup the psql\_cm control tables on the target databases,

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup

# Dump

Dump the current database schema to the specified --sql-path directory, if none
specified it dumps to $PWD/sql

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

# Restore (Not Implemented Yet)

Restore a previously psql-cm dumped database schema into a brand new postgresql
database cluster.

    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" restore

# Example

    $ createdb psqlcm_test
    $ psql psqlcm_test -c 'CREATE SCHEMA schema_one; CREATE SCHEMA schema_two'
    $ echo psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" setup
    $ psql-cm --databases psqlcm_test --uri "postgres://127.0.0.1:5432" dump

