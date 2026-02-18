-- V004__seed_program_types.sql
-- Seeds the program_type table with 5 bilingual program categories.
-- Uses MERGE for idempotency so the script can be re-run safely.
-- AB#1814

MERGE INTO program_type AS target
USING (VALUES
    (1, N'Health',             N'Santé'),
    (2, N'Education',          N'Éducation'),
    (3, N'Infrastructure',     N'Infrastructure'),
    (4, N'Social Services',    N'Services sociaux'),
    (5, N'Environment',        N'Environnement')
) AS source (id, type_name_en, type_name_fr)
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET
        type_name_en = source.type_name_en,
        type_name_fr = source.type_name_fr
WHEN NOT MATCHED THEN
    INSERT (type_name_en, type_name_fr)
    VALUES (source.type_name_en, source.type_name_fr);
GO
