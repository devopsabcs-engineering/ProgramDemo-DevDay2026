-- V005__add_program_budget.sql
-- Adds an optional budget field to the program table.
-- Supports the Phase 7 live-change demo end-to-end feature addition.
-- AB#1838

ALTER TABLE program
    ADD budget DECIMAL(15, 2) NULL;
