-- =====================================================================
-- dim_product.sql
-- Product dimension: one row per product, with English category name.
-- T8 ('unknown' category) and T9 (manual translations) come from staging.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_product CASCADE;

CREATE TABLE mart.dim_product AS
SELECT
    p.product_id,
    p.category_name,
    t.category_name_en,
    p.name_length,
    p.description_length,
    p.photos_qty,
    p.weight_g,
    p.length_cm,
    p.height_cm,
    p.width_cm
FROM staging.stg_products p
LEFT JOIN staging.stg_category_translation t
       ON t.category_name = p.category_name;

ALTER TABLE mart.dim_product ADD PRIMARY KEY (product_id);