-- V005__add_program_budget.sql
-- Adds an optional budget field to the program table.
-- Uses IF NOT EXISTS guard for idempotency.
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
