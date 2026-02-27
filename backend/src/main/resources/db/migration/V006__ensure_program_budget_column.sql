-- V006__ensure_program_budget_column.sql
-- Safety-net migration: ensures the budget column exists on the program table.
-- Guards against the case where V005 was recorded as applied in Flyway history
-- but the ALTER TABLE did not commit (e.g. due to a previous deployment failure).
-- AB#1838

IF NOT EXISTS (
    SELECT 1
    FROM   information_schema.columns
    WHERE  table_name  = 'program'
    AND    column_name = 'budget'
)
BEGIN
    ALTER TABLE program
        ADD budget DECIMAL(15, 2) NULL;
END;
