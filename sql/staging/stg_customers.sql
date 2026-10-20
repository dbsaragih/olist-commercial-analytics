-- =====================================================================
-- stg_customers.sql
-- Staging view for raw.customers.
-- Grain: one row per customer_id (= one per order).
-- T2: customer_unique_id identifies the person; use it for customer analysis.
-- Zip code prefix stays text to keep leading zeros.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_customers CASCADE;

CREATE VIEW staging.stg_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix   AS zip_code_prefix,
    customer_city              AS city,
    customer_state             AS state
FROM raw.customers;