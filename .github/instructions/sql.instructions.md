---
applyTo: "database/**/*.sql"
---
# Azure SQL Instructions

- Target Azure SQL Database.
- Use versioned migration naming: V{number}__{description}.sql (double underscore).
- Include IF NOT EXISTS guards on all CREATE TABLE and CREATE INDEX statements.
- Use NVARCHAR for all text columns to support bilingual content (EN/FR).
- Always include primary key constraints on every table.
- Add appropriate indexes for columns used in WHERE clauses and JOINs.
- Include NOT NULL constraints on required columns.
- Use DATETIME2 for all timestamp columns (not DATETIME).
- Include created_date and updated_date columns on all entity tables.
- Add foreign key constraints with descriptive constraint names.
- Use BIGINT for auto-increment primary keys on high-volume tables.
- Use INT for lookup table primary keys.
- Include comments for non-obvious column purposes.
- Seed data scripts should use MERGE or INSERT with NOT EXISTS guards for idempotency.
