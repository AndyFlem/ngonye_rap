# ngonye_rap — Claude Code Notes

## Database

Connect at the start of each session to verify the local DB is running:

```
PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap
```

| Setting  | Value        |
|----------|--------------|
| Host     | localhost    |
| Port     | 5432         |
| Database | ngonye_rap   |
| User     | postgres     |
| Password | extramild20  |
| Schema   | public       |

These credentials are also in [backend/src/config/config.js](backend/src/config/config.js).

## Schema

The current database schema is in [backend/db/schema.sql](backend/db/schema.sql). Before any DB work, read both the schema and all existing scripts in [backend/db/scripts/](backend/db/scripts/) to understand the true current state — scripts may contain migrations that post-date the base schema.

## DB Changes

Any schema changes or CRUD operations performed by Claude must be written as scripts in [backend/db/scripts/](backend/db/scripts/) — never run ad-hoc SQL directly against the database.

At session start, run a quick connection check:

```bash
PGPASSWORD=extramild20 psql -h localhost -p 5432 -U postgres -d ngonye_rap -c "\dt" 2>&1 | head -5
```
