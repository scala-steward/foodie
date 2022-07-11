### Database
1. Create a database, a corresponding user, and connect the two:
   ```
   > psql -U postgres
   psql> create database <foodie>;
   psql> create user <foodie> with encrypted password <password>;
   psql> grant all privileges on database <foodie> to <foodie>;
   psql> grant pg_read_server_files to "<foodie>";
   ```
   The last command is important for the population of the actual CNF database.
2. The system scans for migrations in the folder `conf/db/migrations/default`
   and applies new ones.
   After a migration one should re-generate database related code:
    1. `sbt slickGenerate` generates the base queries, and types.