# Database Migrations

Flyway migration scripts are the **single source of truth** for the database schema.

## Location

All migration scripts live in:

```
backend/src/main/resources/db/migration/
```

This is the only path on the Java classpath that Flyway scans at runtime. Scripts placed anywhere else are **not executed**.

## Naming Convention

Follow the Flyway versioned migration format:

```
V{version}__{description}.sql
```

Examples:

```
V001__create_program_type_table.sql
V002__create_program_table.sql
```

Rules:

- Version numbers are zero-padded to three digits.
- Use double underscores between version and description.
- Description uses lowercase and underscores.
- Each script must be idempotent where possible (use `IF NOT EXISTS` / `IF EXISTS` guards for DDL).

## Why Not Here?

The `database/` folder is for documentation and reference only. The Dockerfile copies only the `backend/src/` tree into the container image:

```dockerfile
COPY src ./src
```

Any SQL files outside `backend/src/main/resources/db/migration/` never reach the running application.
