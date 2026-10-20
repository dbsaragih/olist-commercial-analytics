-- =====================================================================
-- stg_order_items.sql
-- Staging view for raw.order_items: typed columns and consistent names.
-- One-to-one with the source table: no filters, no joins.
-- T5 (shipping deadline > 30 days after purchase) needs the purchase
-- date from orders, so it is applied in the mart (fact_order_items).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS staging;

DROP VIEW IF EXISTS staging.stg_order_items CASCADE;

CREATE VIEW staging.stg_order_items AS
SELECT
    order_id,
    order_item_id::int                  AS order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::timestamp      AS shipping_limit_ts,
    price::numeric                      AS price,
    freight_value::numeric              AS freight_value
FROM raw.order_items;