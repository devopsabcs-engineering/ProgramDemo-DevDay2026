-- V001__create_program_type_table.sql
-- Creates the program_type lookup table for bilingual program categories.
-- AB#1813

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'program_type')
BEGIN
    CREATE TABLE program_type (
        id            INT           IDENTITY(1,1) NOT NULL,
        type_name_en  NVARCHAR(100) NOT NULL,
        type_name_fr  NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_program_type PRIMARY KEY (id)
    );
END
GO
