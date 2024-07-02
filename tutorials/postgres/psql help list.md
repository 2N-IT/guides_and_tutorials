# work with postgres comands

```sql
#find config file path
psql -U postgres -c 'SHOW config_file'

#find config value loaded from file
psql -U postgres -c 'SHOW log_min_duration_statement'

#reload postgres after config change
sudo sudo systemctl reload postgresql

#another way incase you dont have permissions to systemctl
sudo /etc/init.d/postgresql restart

#Exit psql
\q
```

# Helpful Queries

```sql
#List tables

SELECT table_name FROM information_schema.tables WHERE table_schema='public';

#List indexes

SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    indexname;
```

# Index reports

```sql
SELECT
    tablename,
    count(*) as index_count,
    string_agg(indexname, ',')
FROM
    pg_indexes
WHERE
    schemaname = 'public'
GROUP BY
    tablename
ORDER BY
    index_count;
```

Note to verify with data: Having too many indexes can affect not only write but also read statements performance.

According to [postgres.fm](http://postgres.fm) podcast having more than 12 indexes on a single table start to create lock issues that could cost performance.

# User Management

## create a read-only user

readuser is a name you can name your user something else.

<database_name> need to match the one defined in config/database.yml

```sql
CREATE ROLE readeruser WITH LOGIN PASSWORD 'password';

GRANT CONNECT ON DATABASE <database_name> TO readeruser;

GRANT USAGE ON SCHEMA public TO readeruser;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO readeruser;
```

It is possible this fails with the error:

`` ERROR: tuple concurrently updated ``

The workaround I found was to just list manually all the tables.

```
SELECT string_agg(table_name, ', ') as aggtable_name FROM information_schema.tables WHERE table_schema = 'public';
```

```
GRANT SELECT ON talbe_1, table_2, table_3 ... table_trilion TO XXX;
```
