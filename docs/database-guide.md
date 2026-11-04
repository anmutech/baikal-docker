# Database Guide

This guide outlines the database configuration for mariadb/mysql/postgres.

## Starting order

The `baikal` service in the examples starts only after the database service reports `healthy` (`depends_on: condition: service_healthy`). The `db` services use the healthchecks built into the official images (`mysqladmin ping` / `pg_isready`).
The `baikal` service itself also has a healthcheck, which reports `unhealthy` until first-time setup is complete.

## Mariadb

See [examples/docker-compose.mariadb.yaml](../examples/docker-compose.mariadb.yaml) for a starter template.

Once the container has started, visit it's at: `http://localhost:80/`

At the initialization wizard edit the settings to your preference and set an admin password.
Edit the database settings to the following:

1. Database Backend: `mysql`
2. MySQL host: `db` or the name of your database container
3. MySQL database name: `baikal`
4. MySQL username: `baikal`
5. MySQL password: `ilovecookies` or the password you should have set
6. MySQL CA Certificate: leave empty

You can now start using baikal.

## MySQL

See [examples/docker-compose.mysql.yaml](../examples/docker-compose.mysql.yaml) for a starter template.

Once the container has started, visit it's at: `http://localhost:80/`

At the initialization wizard edit the settings to your preference and set an admin password.
Edit the database settings to the following:

1. Database Backend: `mysql`
2. MySQL host: `db` or the name of your database container
3. MySQL database name: `baikal`
4. MySQL username: `baikal`
5. MySQL password: `ilovecookies` or the password you should have set
6. MySQL CA Certificate: leave empty

You can now start using baikal.

## PostgreSQL

> [!IMPORTANT]
> I would not recommend using PostgreSQL, unless really required.
> PostgreSQL does not automatically upgrade the database version if you change the docker image.
> Upgrading between versions requires both versions of PostgreSQL to be available, for `pg_upgrade` to work.
> If you start with version 18 and want to upgrade in the future to version 19, you have to manually perform the upgrade.

See [examples/docker-compose.postgres.yaml](../examples/docker-compose.postgres.yaml) for a starter template.

Once the container has started, visit it's at: `http://localhost:80/`

At the initialization wizard edit the settings to your preference and set an admin password.
Edit the database settings to the following:

1. Database Backend: `pgsql`
2. PostgreSQL host: `db` or the name of your database container
3. PostgreSQL database name: `baikal`
4. PostgreSQL username: `baikal`
5. PostgreSQL password: `ilovecookies` or the password you should have set

You can now start using baikal.

## Known issues

Requires user feedback, no known issues for now.
