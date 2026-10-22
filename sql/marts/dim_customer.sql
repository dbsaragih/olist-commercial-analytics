-- =====================================================================
-- dim_customer.sql
-- Customer dimension: one row per person (customer_unique_id, T2).
-- Location = most recent order's address (state at the time of each
-- order is stored on fact_orders).
-- is_repeat_customer = 2+ delivered orders in the analysis period (BQ2).
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_customer CASCADE;

CREATE TABLE mart.dim_customer AS
WITH customer_orders AS (
    -- Every order with its person and address, newest first per person
    SELECT
        c.customer_unique_id,
        c.zip_code_prefix,
        c.city,
        c.state,
        o.order_id,
        o.purchase_ts,
        o.is_delivered,
        o.in_analysis_period,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.purchase_ts DESC, o.order_id DESC
        ) AS recency_rank
    FROM staging.stg_customers c
    JOIN staging.stg_orders    o ON o.customer_id = c.customer_id
),
summary AS (
    -- One row per person: dates and order counts
    SELECT
        customer_unique_id,
        MIN(purchase_ts)::date  AS first_order_date,
        MAX(purchase_ts)::date  AS last_order_date,
        COUNT(*)                AS orders_all,
        COUNT(*) FILTER (WHERE is_delivered AND in_analysis_period)
                                AS delivered_orders_in_period
    FROM customer_orders
    GROUP BY customer_unique_id
)
SELECT
    s.customer_unique_id,
    latest.zip_code_prefix,
    latest.city,
    latest.state,
    r.region,
    s.first_order_date,
    s.last_order_date,
    s.orders_all,
    s.delivered_orders_in_period,
    (s.delivered_orders_in_period >= 2) AS is_repeat_customer
FROM summary s
JOIN customer_orders latest
  ON latest.customer_unique_id = s.customer_unique_id
 AND latest.recency_rank = 1
LEFT JOIN staging.stg_state_region r ON r.state = latest.state;

ALTER TABLE mart.dim_customer ADD PRIMARY KEY (customer_unique_id);