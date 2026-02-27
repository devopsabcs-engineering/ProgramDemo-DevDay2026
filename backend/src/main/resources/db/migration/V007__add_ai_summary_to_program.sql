-- V007__add_ai_summary_to_program.sql
-- Add AI summary columns to the program table for automatic document summarization.
-- Columns are nullable because the summary is generated asynchronously by the Azure Function
-- after the blob trigger fires; records exist before the summary is available.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.program')
      AND name = N'ai_summary'
)
BEGIN
    ALTER TABLE program
        ADD ai_summary NVARCHAR(MAX) NULL;
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.program')
      AND name = N'ai_summary_generated_date'
)
BEGIN
    ALTER TABLE program
        ADD ai_summary_generated_date DATETIME2 NULL;
END;
