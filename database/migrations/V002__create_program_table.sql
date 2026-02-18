-- V002__create_program_table.sql
-- Creates the program table for citizen program submissions and review status.
-- AB#1812

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'program')
BEGIN
    CREATE TABLE program (
        id                  BIGINT        IDENTITY(1,1) NOT NULL,
        program_name        NVARCHAR(200) NOT NULL,
        program_description NVARCHAR(MAX) NOT NULL,
        program_type_id     INT           NOT NULL,
        status              NVARCHAR(50)  NOT NULL CONSTRAINT DF_program_status DEFAULT 'DRAFT',
        submitted_by        NVARCHAR(100) NULL,
        reviewed_by         NVARCHAR(100) NULL,
        review_comments     NVARCHAR(MAX) NULL,
        document_url        NVARCHAR(500) NULL,
        created_date        DATETIME2     NOT NULL CONSTRAINT DF_program_created_date DEFAULT GETUTCDATE(),
        updated_date        DATETIME2     NOT NULL CONSTRAINT DF_program_updated_date DEFAULT GETUTCDATE(),
        CONSTRAINT PK_program PRIMARY KEY (id),
        CONSTRAINT FK_program_program_type FOREIGN KEY (program_type_id)
            REFERENCES program_type (id)
    );
END
GO

-- Indexes for common query patterns
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_program_status' AND object_id = OBJECT_ID('program'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_program_status
        ON program (status);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_program_submitted_by' AND object_id = OBJECT_ID('program'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_program_submitted_by
        ON program (submitted_by);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_program_program_type_id' AND object_id = OBJECT_ID('program'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_program_program_type_id
        ON program (program_type_id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_program_created_date' AND object_id = OBJECT_ID('program'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_program_created_date
        ON program (created_date);
END
GO
