# 0th-Migration

My own notes on setting up the database for Hasura to operate within:

**Note**: This was handy to install the pgcrypto extension on Ubuntu 16.04 for
postgres 9.3: <https://www.postgresql.org/download/linux/ubuntu/>

> sudo apt-get install postgresql-contrib-9.3


### Steps

1. Make the user

```
psql> create role jobs_user with password '...';
```

2. Make the database

```
> createdb scirate_jobs_live -O jobs_user
```

2. Install `pgcrypto` extension:

```
> create extension pgcrypto;
```

Then restart postgres.
