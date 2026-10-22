-- =====================================================================
-- fact_order_items.sql
-- Fact table: one row per item line in an order.
-- Used for BQ1 (categories), BQ4 (sellers), BQ5 (freight).
-- delivery_state/region copied from the order (address at time of order).
-- T5: excl_handover = shipping deadline more than 30 days after purchase.
-- freight_share is non-additive: never average it; in Power BI use
-- SUM(freight_value) / SUM(price + freight_value).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.fact_order_items CASCADE;

CREATE TABLE mart.fact_order_items AS
SELECT
    -- Keys
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    c.customer_unique_id,
    TO_CHAR(o.purchase_ts, 'YYYYMMDD')::int          AS purchase_date_key,

    -- Order context
    o.order_status,
    o.is_delivered,
    o.in_analysis_period,
    c.state                                          AS delivery_state,
    r.region                                         AS delivery_region,

    -- Measures
    i.price,                                         -- additive (GMV)
    i.freight_value,                                 -- additive
    ROUND(i.freight_value / (i.price + i.freight_value), 4)
                                                     AS freight_share,  -- non-additive

    -- Seller deadline and T5 flag
    i.shipping_limit_ts,
    (i.shipping_limit_ts > o.purchase_ts + INTERVAL '30 days')
                                                     AS excl_handover   -- T5
FROM staging.stg_order_items i
JOIN staging.stg_orders    o ON o.order_id    = i.order_id
JOIN staging.stg_customers c ON c.customer_id = o.customer_id
LEFT JOIN staging.stg_state_region r ON r.state = c.state;

ALTER TABLE mart.fact_order_items
    ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE mart.fact_order_items
    ADD CONSTRAINT fk_foi_product  FOREIGN KEY (product_id)
        REFERENCES mart.dim_product (product_id),
    ADD CONSTRAINT fk_foi_seller   FOREIGN KEY (seller_id)
        REFERENCES mart.dim_seller (seller_id),
    ADD CONSTRAINT fk_foi_customer FOREIGN KEY (customer_unique_id)
        REFERENCES mart.dim_customer (customer_unique_id),
    ADD CONSTRAINT fk_foi_date     FOREIGN KEY (purchase_date_key)
        REFERENCES mart.dim_date (date_key);