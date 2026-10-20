-- =====================================================================
-- stg_sellers.sql
-- Staging view for raw.sellers. Grain: one row per seller.
-- Zip code prefix stays text to keep leading zeros.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_sellers CASCADE;

CREATE VIEW staging.stg_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix     AS zip_code_prefix,
    seller_city                AS city,
    seller_state               AS state
FROM raw.sellers;