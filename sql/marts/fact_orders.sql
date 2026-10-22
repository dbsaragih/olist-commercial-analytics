-- =====================================================================
-- fact_orders.sql
-- Fact table: one row per order (all statuses; filter with flags).
-- Used for BQ2 (repeat), BQ3 (delivery), BQ5 (ratings).
-- Built from fact_order_items (order totals, T5) so logic lives once.
-- Assumptions:
--   * Order deadline = latest item deadline (handover late only if it
--     missed every item's deadline).
--   * Day counts use calendar dates; positive days_vs_estimate = late.
--   * Delivery measures are NULL (not 0) when not delivered.
-- Treatments: T3, T4 (from staging), T5 (from items), T6 latest review,
--             T7 has_review.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.fact_orders CASCADE;

CREATE TABLE mart.fact_orders AS
WITH items AS (
    SELECT
        order_id,
        COUNT(*)                AS items_count,
        SUM(price)              AS order_gmv,
        SUM(freight_value)      AS order_freight,
        MAX(shipping_limit_ts)  AS shipping_limit_ts,
        BOOL_OR(excl_handover)  AS excl_handover
    FROM mart.fact_order_items
    GROUP BY order_id
),
latest_review AS (
    SELECT order_id, review_score
    FROM staging.stg_order_reviews
    WHERE is_latest_for_order                          -- T6
)
SELECT
    -- Keys
    o.order_id,
    c.customer_unique_id,
    TO_CHAR(o.purchase_ts,  'YYYYMMDD')::int           AS purchase_date_key,
    TO_CHAR(o.delivered_ts, 'YYYYMMDD')::int           AS delivered_date_key,

    -- Order context
    o.order_status,
    o.is_delivered,
    o.in_analysis_period,
    c.state                                            AS delivery_state,
    r.region                                           AS delivery_region,

    -- Size and value (additive)
    COALESCE(i.items_count, 0)                         AS items_count,
    COALESCE(i.order_gmv, 0)                           AS order_gmv,
    COALESCE(i.order_freight, 0)                       AS order_freight,

    -- Delivery timing in days (NULL when not delivered)
    o.delivered_ts::date - o.purchase_ts::date         AS delivery_days,
    o.delivered_ts::date - o.estimated_delivery_date   AS days_vs_estimate,
    (o.delivered_ts::date > o.estimated_delivery_date) AS is_late,
    o.carrier_handover_ts::date - o.purchase_ts::date  AS seller_handover_days,
    o.delivered_ts::date - o.carrier_handover_ts::date AS carrier_transit_days,
    (o.carrier_handover_ts > i.shipping_limit_ts)      AS is_handover_late,

    -- Reviews
    lr.review_score,
    (lr.order_id IS NOT NULL)                          AS has_review,      -- T7

    -- Exclusion flags
    o.excl_delivery_time,                                                 -- T3
    o.excl_carrier_leg,                                                   -- T4
    COALESCE(i.excl_handover, FALSE)                   AS excl_handover   -- T5
FROM staging.stg_orders o
JOIN staging.stg_customers c       ON c.customer_id = o.customer_id
LEFT JOIN staging.stg_state_region r ON r.state     = c.state
LEFT JOIN items i                  ON i.order_id    = o.order_id
LEFT JOIN latest_review lr         ON lr.order_id   = o.order_id;

ALTER TABLE mart.fact_orders
    ADD PRIMARY KEY (order_id);

ALTER TABLE mart.fact_orders
    ADD CONSTRAINT fk_fo_customer       FOREIGN KEY (customer_unique_id)
        REFERENCES mart.dim_customer (customer_unique_id),
    ADD CONSTRAINT fk_fo_purchase_date  FOREIGN KEY (purchase_date_key)
        REFERENCES mart.dim_date (date_key),
    ADD CONSTRAINT fk_fo_delivered_date FOREIGN KEY (delivered_date_key)
        REFERENCES mart.dim_date (date_key);