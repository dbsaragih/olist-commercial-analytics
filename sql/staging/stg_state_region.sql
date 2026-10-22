-- =====================================================================
-- stg_state_region.sql
-- Reference mapping of Brazilian states to the five official regions.
-- Defined once here and reused by dimensions and facts (DRY).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_state_region CASCADE;

CREATE VIEW staging.stg_state_region AS
SELECT state, region
FROM (VALUES
    ('AC', 'North'), ('AM', 'North'), ('AP', 'North'), ('PA', 'North'),
    ('RO', 'North'), ('RR', 'North'), ('TO', 'North'),
    ('AL', 'Northeast'), ('BA', 'Northeast'), ('CE', 'Northeast'),
    ('MA', 'Northeast'), ('PB', 'Northeast'), ('PE', 'Northeast'),
    ('PI', 'Northeast'), ('RN', 'Northeast'), ('SE', 'Northeast'),
    ('DF', 'Center-West'), ('GO', 'Center-West'),
    ('MS', 'Center-West'), ('MT', 'Center-West'),
    ('ES', 'Southeast'), ('MG', 'Southeast'),
    ('RJ', 'Southeast'), ('SP', 'Southeast'),
    ('PR', 'South'), ('RS', 'South'), ('SC', 'South')
) AS mapping(state, region);