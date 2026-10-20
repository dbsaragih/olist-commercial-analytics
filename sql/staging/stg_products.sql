-- =====================================================================
-- stg_products.sql
-- Staging view for raw.products. Grain: one row per product.
-- T8: products without a category are labelled 'unknown' so their
--     sales stay in totals.
-- Source column names misspell "length" as "lenght"; corrected here.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_products CASCADE;

CREATE VIEW staging.stg_products AS
SELECT
    product_id,
    COALESCE(product_category_name, 'unknown')   AS category_name,   -- T8
    product_name_lenght::numeric::int            AS name_length,
    product_description_lenght::numeric::int     AS description_length,
    product_photos_qty::numeric::int             AS photos_qty,
    product_weight_g::numeric                    AS weight_g,
    product_length_cm::numeric                   AS length_cm,
    product_height_cm::numeric                   AS height_cm,
    product_width_cm::numeric                    AS width_cm
FROM raw.products;