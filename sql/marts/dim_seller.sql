-- =====================================================================
-- dim_seller.sql
-- Seller dimension: one row per seller, with region.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_seller CASCADE;

CREATE TABLE mart.dim_seller AS
SELECT
    s.seller_id,
    s.zip_code_prefix,
    s.city,
    s.state,
    r.region
FROM staging.stg_sellers s
LEFT JOIN staging.stg_state_region r ON r.state = s.state;

ALTER TABLE mart.dim_seller ADD PRIMARY KEY (seller_id);