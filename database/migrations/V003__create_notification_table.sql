-- V003__create_notification_table.sql
-- Creates the notification table for tracking email notifications to citizens.
-- AB#1810

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'notification')
BEGIN
    CREATE TABLE notification (
        id                 BIGINT        IDENTITY(1,1) NOT NULL,
        program_id         BIGINT        NOT NULL,
        recipient_email    NVARCHAR(200) NOT NULL,
        notification_type  NVARCHAR(50)  NOT NULL,  -- SUBMISSION_CONFIRMATION, DECISION
        sent_date          DATETIME2     NULL,
        status             NVARCHAR(50)  NOT NULL CONSTRAINT DF_notification_status DEFAULT 'PENDING',
        created_date       DATETIME2     NOT NULL CONSTRAINT DF_notification_created_date DEFAULT GETUTCDATE(),
        updated_date       DATETIME2     NOT NULL CONSTRAINT DF_notification_updated_date DEFAULT GETUTCDATE(),
        created_by         NVARCHAR(100) NULL,
        CONSTRAINT PK_notification PRIMARY KEY (id),
        CONSTRAINT FK_notification_program FOREIGN KEY (program_id)
            REFERENCES program (id)
    );
END
GO

-- Indexes for common query patterns
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_notification_program_id' AND object_id = OBJECT_ID('notification'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_notification_program_id
        ON notification (program_id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_notification_status' AND object_id = OBJECT_ID('notification'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_notification_status
        ON notification (status);
END
GO
